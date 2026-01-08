from core.redis import get_redis
from core.config import SESSION_TTL


async def get_user_id_by_session(session_id: str) -> str | None:
    redis = get_redis()
    user_id = await redis.get(f"session:{session_id}")
    return user_id


async def create_session(session_id: str, user_id: str):
    redis = get_redis()
    await redis.set(
        f"session:{session_id}",
        user_id,
        ex=SESSION_TTL
    )
