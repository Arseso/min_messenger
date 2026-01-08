from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from typing import List
from datetime import datetime

from app.core.socket_manager import manager
from app.models.schemas import MessageCreate, MessageResponse
from app.core.database import get_db_connection
from app.crud import message as crud_message
from app.crud import chat as crud_chat
from app.core.utils import save_file

router = APIRouter(tags=["Messages"])

@router.get("/messages/{chat_id}", response_model=List[MessageResponse])
def get_messages(chat_id: int, conn = Depends(get_db_connection)):
    return crud_message.get_messages_by_chat(conn, chat_id)

@router.post("/messages/send")
async def send_msg(msg_data: MessageCreate, conn = Depends(get_db_connection)):
    try:
        crud_chat.update_last_message_time(conn, msg_data.chat_id)

        msg_id = await crud_message.create_message(conn, msg_data)

        return {"status": "ok", "message_id": msg_id}

    except Exception as e:
        print(f"Error sending message: {e}")
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/upload/message_image")
async def upload_message_image(file: UploadFile = File(...)):
    try:
        url = save_file(file, "messages")
        return {"image_url": url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/messages/read_all")
async def read_all_messages(data: dict, conn = Depends(get_db_connection)):
    chat_id = data.get("chat_id")
    user_id = data.get("user_id")

    if not chat_id or not user_id:
        raise HTTPException(status_code=400, detail="Missing chat_id or user_id")

    updated_count = crud_message.mark_messages_as_read(conn, chat_id, user_id)

    if updated_count > 0:
        await manager.broadcast({
            "type": "messages_read",
            "chat_id": chat_id,
            "reader_id": user_id
        }, chat_id)

    return {"status": "success", "updated": updated_count}