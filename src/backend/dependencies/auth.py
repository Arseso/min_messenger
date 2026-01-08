from fastapi import Header, HTTPException, status
from core.redis import get_redis


async def get_current_user(
    x_session_token: str = Header(...)
) -> str:
    redis = get_redis()

    user_id = await redis.get(f"session:{x_session_token}")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="INVALID_SESSION"
        )

    return user_id
