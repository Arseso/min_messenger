from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class UserBase(BaseModel):
    username: str

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    user_id: int
    avatar_url: Optional[str] = None

    class Config:
        from_attributes = True

class ChatCreate(BaseModel):
    name: str
    is_group: bool = True
    created_by: int
    participant_ids: List[int] = []

class ChatResponse(BaseModel):
    chat_id: int
    chat_name: Optional[str]
    chat_type: str
    unread_count: int = 0
    last_message_content: Optional[str] = None
    created_by: int
    last_message_at: Optional[datetime]
    created_at: Optional[datetime]
    participant_ids: List[int]

class MessageCreate(BaseModel):
    sender_id: int
    chat_id: int
    content: str

class MessageResponse(BaseModel):
    message_id: int
    sender_id: int
    chat_id: int
    content: str
    status: str
    created_at: datetime
    sender_name: Optional[str] = None
    sender_avatar: Optional[str] = None

class MemberUpdate(BaseModel):
    chat_id: int
    user_id: int