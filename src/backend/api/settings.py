from fastapi import APIRouter, Depends
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from db.base import get_db
from db.models import UserSettings, Blacklist
from dependencies.auth import get_current_user
from schemas.settings import SettingsResponse, UpdateSettingsRequest

router = APIRouter(prefix="/api/settings", tags=["settings"])


@router.get("", response_model=SettingsResponse)
async def get_settings(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    q = select(UserSettings).where(UserSettings.user_id == user_id)
    settings = (await db.execute(q)).scalar_one()

    return SettingsResponse(
        private_profile=settings.private_profile,
        allow_invites=settings.allow_invites
    )


@router.patch("")
async def update_settings(
    data: UpdateSettingsRequest,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    q = select(UserSettings).where(UserSettings.user_id == user_id)
    settings = (await db.execute(q)).scalar_one()

    if data.private_profile is not None:
        settings.private_profile = data.private_profile

    if data.allow_invites is not None:
        settings.allow_invites = data.allow_invites

    await db.commit()
    return {"status": "ok"}


@router.post("/blacklist/{blocked_user_id}")
async def add_to_blacklist(
    blocked_user_id: str,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    db.add(Blacklist(
        user_id=user_id,
        blocked_user_id=blocked_user_id
    ))
    await db.commit()
    return {"status": "ok"}


@router.delete("/blacklist/{blocked_user_id}")
async def remove_from_blacklist(
    blocked_user_id: str,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    await db.execute(
        delete(Blacklist).where(
            Blacklist.user_id == user_id,
            Blacklist.blocked_user_id == blocked_user_id
        )
    )
    await db.commit()
    return {"status": "ok"}

