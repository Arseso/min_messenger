from services.privacy_service import check_dm_permissions, PrivacyError
from db.base import AsyncSessionLocal
from ws.manager import ws_manager
from core.redis import get_redis
from core.config import MESSAGE_TTL
import json


async def send_dm(from_user: str, to_user: str, payload: dict):
    async with AsyncSessionLocal() as db:
        try:
            await check_dm_permissions(db, from_user, to_user)
        except PrivacyError as e:
            await ws_manager.send_to_user(from_user, {
                "type": "error",
                "payload": {
                    "msg_id": payload["msg_id"],
                    "code": e.code
                }
            })
            return

    redis = get_redis()

    message = {
        "type": "message",
        "payload": {
            "msg_id": payload["msg_id"],
            "from_user_id": from_user,
            "text": payload["text"]
        }
    }

    online = await redis.exists(f"presence:{to_user}")

    if online:
        await ws_manager.send_to_user(to_user, message)
    else:
        key = f"pending:dm:{to_user}"
        await redis.rpush(key, json.dumps(message))
        await redis.expire(key, MESSAGE_TTL)

    await redis.sadd(f"ack:{payload['msg_id']}", to_user)
    await redis.expire(f"ack:{payload['msg_id']}", MESSAGE_TTL)
