from redis.asyncio import Redis
from core.config import REDIS_URL

redis: Redis | None = None


async def init_redis():
    global redis
    redis = Redis.from_url(REDIS_URL, decode_responses=True)


def get_redis() -> Redis:
    assert redis is not None, "Redis not initialized"
    return redis
