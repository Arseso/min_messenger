from app.crud import chat as crud_chat
from datetime import datetime
from app.core.socket_manager import manager
from app.models.schemas import MessageCreate

def get_messages_by_chat(conn, chat_id: int):
    cursor = conn.cursor(dictionary=True)
    query = """
        SELECT m.*, u.username as sender_name, u.avatar_url as sender_avatar
        FROM messages m
        JOIN users u ON m.sender_id = u.user_id
        WHERE m.chat_id = %s
        ORDER BY m.created_at ASC
    """
    cursor.execute(query, (chat_id,))
    return cursor.fetchall()

async def create_message(conn, msg_data: MessageCreate):
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "INSERT INTO messages (sender_id, chat_id, content) VALUES (%s, %s, %s)",
        (msg_data.sender_id, msg_data.chat_id, msg_data.content)
    )
    message_id = cursor.lastrowid
    conn.commit()

    cursor.execute(
        "SELECT username, avatar_url FROM users WHERE user_id = %s",
        (msg_data.sender_id,)
    )
    sender_info = cursor.fetchone()

    participant_ids = crud_chat.get_participant_ids(conn, msg_data.chat_id)
    is_anyone_online = False

    for u_id in participant_ids:
        if u_id != msg_data.sender_id:
            if u_id in manager.user_notifications and manager.user_notifications[u_id]:
                is_anyone_online = True
                break

    final_status = "delivered" if is_anyone_online else "sent"

    if is_anyone_online:
        cursor.execute("UPDATE messages SET status = 'delivered' WHERE message_id = %s", (message_id,))
        conn.commit()

    broadcast_data = {
        "type": "new_message",
        "message_id": message_id,
        "sender_id": msg_data.sender_id,
        "chat_id": msg_data.chat_id,
        "content": msg_data.content,
        "status": final_status,
        "created_at": str(datetime.now()),
        "sender_name": sender_info.get('username', "Пользователь"),
        "sender_avatar": sender_info.get('avatar_url', None),
    }
    await manager.broadcast(broadcast_data, msg_data.chat_id)

    for p_id in participant_ids:
        await manager.notify_user(p_id, broadcast_data)

    return message_id

def mark_messages_as_read(conn, chat_id: int, user_id: int):
    cursor = conn.cursor()
    try:
        query = """
            UPDATE messages
            SET status = 'read'
            WHERE chat_id = %s
              AND sender_id != %s
              AND status != 'read'
        """
        cursor.execute(query, (chat_id, user_id))
        conn.commit()
        return cursor.rowcount
    except Exception as e:
        print(f"Error in mark_messages_as_read: {e}")
        conn.rollback()
        return 0
    finally:
        cursor.close()

async def mark_undelivered_as_delivered(conn, user_id: int):
    cursor = conn.cursor(dictionary=True)
    try:
        query = """
            SELECT m.message_id, m.chat_id, m.sender_id
            FROM messages m
            JOIN user_chats uc ON m.chat_id = uc.chat_id
            WHERE uc.user_id = %s AND m.sender_id != %s AND m.status = 'sent'
        """
        cursor.execute(query, (user_id, user_id))
        undelivered = cursor.fetchall()

        if not undelivered: return

        for msg in undelivered:
            cursor.execute("UPDATE messages SET status = 'delivered' WHERE message_id = %s", (msg['message_id'],))
            conn.commit()

            await manager.broadcast({
                "type": "message_status_update",
                "message_id": msg['message_id'],
                "status": "delivered"
            }, msg['chat_id'])

    except Exception as e:
        print(f"Error in delivery push: {e}")
