import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db.models import Group, GroupMember, UserSettings


class GroupError(Exception):
    def __init__(self, code: str):
        self.code = code


async def create_group(
    db: AsyncSession,
    owner_id: str,
    name: str
) -> str:
    group_id = str(uuid.uuid4())

    db.add(Group(
        id=group_id,
        owner_id=owner_id,
        name=name
    ))

    db.add(GroupMember(
        group_id=group_id,
        user_id=owner_id,
        role="owner"
    ))

    await db.commit()
    return group_id


async def add_member(
    db: AsyncSession,
    group_id: str,
    inviter_id: str,
    new_user_id: str
):
    q = select(GroupMember).where(
        GroupMember.group_id == group_id,
        GroupMember.user_id == inviter_id
    )
    if not (await db.execute(q)).scalar_one_or_none():
        raise GroupError("NOT_MEMBER")

    # проверка allow_invites
    q = select(UserSettings.allow_invites).where(
        UserSettings.user_id == new_user_id
    )
    result = (await db.execute(q)).scalar_one_or_none()
    if result is None:
        raise GroupError("USER_NOT_FOUND")
    if not result:
        raise GroupError("INVITES_DISABLED")

    q = select(GroupMember).where(
        GroupMember.group_id == group_id,
        GroupMember.user_id == new_user_id
    )
    if (await db.execute(q)).scalar_one_or_none():
        raise GroupError("ALREADY_IN_GROUP")

    db.add(GroupMember(
        group_id=group_id,
        user_id=new_user_id,
        role="member"
    ))

    await db.commit()
