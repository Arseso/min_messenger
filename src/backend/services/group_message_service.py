import json
from sqlalchemy import select

from core.redis import get_redis
from core.config import MESSAGE_TTL
from db.base import AsyncSessionLocal
from db.models import GroupMember
from ws.manager import ws_manager


async def send_group_message(
    from_user: str,
    group_id: str,
    payload: dict
):
    async with AsyncSessionLocal() as db:
        q = select(GroupMember.user_id).where(
            GroupMember.group_id == group_id
        )
        members = [row[0] for row in (await db.execute(q)).all()]

        if from_user not in members:
            await ws_manager.send_to_user(from_user, {
                "type": "error",
                "payload": {
                    "msg_id": payload["msg_id"],
                    "code": "GROUP_NOT_MEMBER"
                }
            })
            return

    redis = get_redis()

    message = {
        "type": "group_message",
        "payload": {
            "msg_id": payload["msg_id"],
            "group_id": group_id,
            "from_user_id": from_user,
            "text": payload["text"]
        }
    }

    for user_id in members:
        if user_id == from_user:
            continue

        online = await redis.exists(f"presence:{user_id}")

        if online:
            await ws_manager.send_to_user(user_id, message)
        else:
            key = f"pending:group:{group_id}:{user_id}"
            await redis.rpush(key, json.dumps(message))
            await redis.expire(key, MESSAGE_TTL)

        await redis.sadd(f"ack:{payload['msg_id']}", user_id)

    await redis.expire(f"ack:{payload['msg_id']}", MESSAGE_TTL)
