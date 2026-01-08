from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from db.models import FriendRequest, Contact


class FriendError(Exception):
    def __init__(self, code: str):
        self.code = code


async def send_friend_request(
    db: AsyncSession,
    from_user: str,
    to_user: str
):
    if from_user == to_user:
        raise FriendError("SELF_REQUEST")

    q = select(Contact).where(
        Contact.user_id == from_user,
        Contact.contact_id == to_user
    )
    if (await db.execute(q)).scalar_one_or_none():
        raise FriendError("ALREADY_FRIENDS")

    # заявка уже есть?
    q = select(FriendRequest).where(
        FriendRequest.from_user_id == from_user,
        FriendRequest.to_user_id == to_user
    )
    if (await db.execute(q)).scalar_one_or_none():
        raise FriendError("REQUEST_EXISTS")

    db.add(FriendRequest(
        from_user_id=from_user,
        to_user_id=to_user
    ))
    await db.commit()


async def accept_friend_request(
    db: AsyncSession,
    from_user: str,
    to_user: str
):

    q = select(FriendRequest).where(
        FriendRequest.from_user_id == from_user,
        FriendRequest.to_user_id == to_user
    )
    req = (await db.execute(q)).scalar_one_or_none()

    if not req:
        raise FriendError("REQUEST_NOT_FOUND")

    await db.execute(
        delete(FriendRequest).where(
            FriendRequest.from_user_id == from_user,
            FriendRequest.to_user_id == to_user
        )
    )

    db.add_all([
        Contact(user_id=from_user, contact_id=to_user),
        Contact(user_id=to_user, contact_id=from_user)
    ])

    await db.commit()
