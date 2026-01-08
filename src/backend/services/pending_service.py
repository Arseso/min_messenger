import json
from core.redis import get_redis
from ws.manager import ws_manager


async def deliver_pending_dm(user_id: str):
    redis = get_redis()
    key = f"pending:dm:{user_id}"

    while True:
        raw = await redis.lpop(key)
        if not raw:
            break

        message = json.loads(raw)
        await ws_manager.send_to_user(user_id, message)
        
        
async def deliver_pending_groups(user_id: str):
    redis = get_redis()

    pattern = f"pending:group:*:{user_id}"
    keys = await redis.keys(pattern)

    for key in keys:
        while True:
            raw = await redis.lpop(key)
            if not raw:
                break

            message = json.loads(raw)
            await ws_manager.send_to_user(user_id, message)

