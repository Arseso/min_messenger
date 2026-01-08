from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect, Depends
from typing import List
from app.models.schemas import ChatCreate, ChatResponse, MemberUpdate
from app.core.socket_manager import manager
from app.core.database import get_db_connection
from app.crud import chat as crud_chat
from app.crud import message as crud_message
from contextlib import closing

router = APIRouter(tags=["Chats"])

@router.get("/chats/{user_id}", response_model=List[ChatResponse])
def get_my_chats(user_id: int, conn = Depends(get_db_connection)):
    return crud_chat.get_user_chats(conn, user_id)

@router.post("/chats/create")
def create_chat(chat_data: ChatCreate, conn = Depends(get_db_connection)):
    try:
        chat_id = crud_chat.create_chat(conn, chat_data)
        return {"chat_id": chat_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chats/get_or_create_private")
async def get_or_create_private(data: dict, conn = Depends(get_db_connection)):
    user1 = data.get("creator_id")
    user2 = data.get("target_id")

    existing_chat = crud_chat.get_private_chat_between_users(conn, user1, user2)

    if existing_chat:
        return {"chat_id": existing_chat['chat_id']}

    new_id = crud_chat.create_private_chat(conn, user1, user2)
    return {"chat_id": new_id}

@router.post("/chats/add_member")
def add_member(data: MemberUpdate, conn = Depends(get_db_connection)):
    try:
        crud_chat.add_chat_member(conn, data.chat_id, data.user_id)
        return {"status": "added"}
    except:
        return {"status": "already_in_chat"}

@router.post("/chats/remove_member")
def remove_member(data: dict, conn = Depends(get_db_connection)):
    chat_id = data.get("chat_id")
    user_id = data.get("user_id")

    if not chat_id or not user_id:
        raise HTTPException(status_code=400, detail="ID чата и пользователя обязательны")

    success = crud_chat.remove_participant(conn, chat_id, user_id)

    if success:
        return {"status": "success", "message": "Участник удален"}
    else:
        raise HTTPException(status_code=404, detail="Участник не найден")

@router.websocket("/ws/{chat_id}")
async def websocket_endpoint(websocket: WebSocket, chat_id: int):
    await manager.connect(websocket, chat_id)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, chat_id)

@router.websocket("/ws/notifications/{user_id}")
async def notifications_endpoint(websocket: WebSocket, user_id: int):
    db_gen = get_db_connection()
    conn = next(db_gen)

    await manager.connect_notifications(websocket, user_id)

    try:
        await crud_message.mark_undelivered_as_delivered(conn, user_id)

        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect_notifications(websocket, user_id)
    except Exception as e:
        print(f"WS Error: {e}")
    finally:
        try:
            next(db_gen)
        except StopIteration:
            pass