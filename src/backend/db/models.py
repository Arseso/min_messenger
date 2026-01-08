from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class User(Base):
    __tablename__ = "users"

    id = Column(UUID, primary_key=True)
    username = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)


class Contact(Base):
    __tablename__ = "contacts"

    user_id = Column(UUID, primary_key=True)
    contact_id = Column(UUID, primary_key=True)


class Blacklist(Base):
    __tablename__ = "blacklist"

    user_id = Column(UUID, primary_key=True)
    blocked_user_id = Column(UUID, primary_key=True)


class UserSettings(Base):
    __tablename__ = "user_settings"

    user_id = Column(UUID, primary_key=True)
    private_profile = Column(Boolean, default=False)
    allow_invites = Column(Boolean, default=True)


class FriendRequest(Base):
    __tablename__ = "friend_requests"

    from_user_id = Column(UUID, primary_key=True)
    to_user_id = Column(UUID, primary_key=True)
    

class Group(Base):
    __tablename__ = "groups"

    id = Column(UUID, primary_key=True)
    owner_id = Column(UUID, nullable=False)
    name = Column(String, nullable=False)


class GroupMember(Base):
    __tablename__ = "group_members"

    group_id = Column(UUID, primary_key=True)
    user_id = Column(UUID, primary_key=True)
    role = Column(String, nullable=False)