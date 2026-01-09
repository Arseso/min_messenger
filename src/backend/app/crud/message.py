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
    cursor = conn.cursor()
    
    # 1. Сохраняем в БД (по умолчанию 'sent')
    cursor.execute(
        "INSERT INTO messages (sender_id, chat_id, content) VALUES (%s, %s, %s)",
        (msg_data.sender_id, msg_data.chat_id, msg_data.content)
    )
    message_id = cursor.lastrowid
    conn.commit()

    # 2. Проверяем, онлайн ли кто-то из участников (кроме отправителя)
    participant_ids = crud_chat.get_participant_ids(conn, msg_data.chat_id)
    is_anyone_online = False

    for u_id in participant_ids:
        if u_id != msg_data.sender_id:
            # Проверяем наличие в user_notifications (сокет уведомлений)
            if u_id in manager.user_notifications and manager.user_notifications[u_id]:
                is_anyone_online = True
                break

    # 3. Определяем итоговый статус для рассылки
    final_status = "delivered" if is_anyone_online else "sent"

    # 4. Если онлайн, обновляем в БД сразу
    if is_anyone_online:
        cursor.execute("UPDATE messages SET status = 'delivered' WHERE message_id = %s", (message_id,))
        conn.commit()

    # 5. ОТПРАВЛЯЕМ ОДИН РАЗ всем участникам чата
    broadcast_data = {
        "type": "new_message",
        "message_id": message_id,
        "sender_id": msg_data.sender_id,
        "chat_id": msg_data.chat_id,
        "content": msg_data.content,
        "status": final_status, # Сразу правильный статус!
        "created_at": str(datetime.now())
    }
    await manager.broadcast(broadcast_data, msg_data.chat_id)

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
        # Ищем чужие сообщения в моих чатах, которые еще не 'delivered'
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

            # Уведомляем чат, что сообщение доставлено
            await manager.broadcast({
                "type": "message_status_update",
                "message_id": msg['message_id'],
                "status": "delivered"
            }, msg['chat_id'])

    except Exception as e:
        print(f"Error in delivery push: {e}")