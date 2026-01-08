from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db.models import Contact, Blacklist, UserSettings


class PrivacyError(Exception):
    def __init__(self, code: str):
        self.code = code


async def check_dm_permissions(
    db: AsyncSession,
    from_user: str,
    to_user: str
):
    if from_user == to_user:
        raise PrivacyError("SELF_MESSAGE")

    # 1. blacklist
    q = select(Blacklist).where(
        Blacklist.user_id == to_user,
        Blacklist.blocked_user_id == from_user
    )
    if (await db.execute(q)).scalar_one_or_none():
        raise PrivacyError("BLOCKED")

    # 2. friendship
    q = select(Contact).where(
        Contact.user_id == from_user,
        Contact.contact_id == to_user
    )
    is_friend = (await db.execute(q)).scalar_one_or_none() is not None

    # 3. private profile
    q = select(UserSettings.private_profile).where(
        UserSettings.user_id == to_user
    )
    result = (await db.execute(q)).scalar_one_or_none()
    private = result if result is not None else False

    if private and not is_friend:
        raise PrivacyError("PRIVATE_PROFILE")

    if not is_friend:
        raise PrivacyError("NOT_FRIEND")
