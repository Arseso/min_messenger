import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db.base import get_db
from db.models import User, UserSettings
from schemas.auth import RegisterRequest, LoginRequest, LoginResponse
from core.security import hash_password, verify_password
from core.redis import get_redis
from dependencies.auth import get_current_user
from core.config import SESSION_TTL

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/register")
async def register(
    data: RegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    q = select(User).where(User.username == data.username)
    if (await db.execute(q)).scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="USERNAME_TAKEN"
        )

    user_id = str(uuid.uuid4())

    db.add(User(
        id=user_id,
        username=data.username,
        password_hash=hash_password(data.password)
    ))

    db.add(UserSettings(
        user_id=user_id,
        private_profile=False,
        allow_invites=True
    ))

    await db.commit()

    return {"status": "ok"}


@router.post("/login", response_model=LoginResponse)
async def login(
    data: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    q = select(User).where(User.username == data.username)
    user = (await db.execute(q)).scalar_one_or_none()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="INVALID_CREDENTIALS"
        )

    session_token = str(uuid.uuid4())

    redis = get_redis()
    await redis.set(
        f"session:{session_token}",
        user.id,
        ex=SESSION_TTL
    )

    return LoginResponse(session_token=session_token)


@router.post("/logout")
async def logout(
    user_id: str = Depends(get_current_user),
    x_session_token: str = Depends(lambda x_session_token=Header(...): x_session_token)
):
    redis = get_redis()
    await redis.delete(f"session:{x_session_token}")

    return {"status": "ok"}
