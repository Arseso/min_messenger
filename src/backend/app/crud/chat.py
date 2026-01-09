from app.models.schemas import ChatCreate

def get_user_chats(conn, user_id: int):
    cursor = conn.cursor(dictionary=True)

    query = """
        SELECT
            c.chat_id,
            c.chat_name,
            c.chat_type,
            c.created_by,
            c.last_message_at,
            c.created_at,
            (SELECT COUNT(*)
             FROM messages m
             WHERE m.chat_id = c.chat_id
                AND m.status != 'read'
                AND m.sender_id != %s) as unread_count,
             (SELECT content
                FROM messages m
                WHERE m.chat_id = c.chat_id
                ORDER BY m.created_at DESC LIMIT 1) as last_message_content
        FROM chats c
        JOIN user_chats uc ON c.chat_id = uc.chat_id
        WHERE uc.user_id = %s
        ORDER BY c.last_message_at DESC
    """
    cursor.execute(query, (user_id, user_id))
    chats = cursor.fetchall()

    if not chats:
        return []

    chat_ids = [c['chat_id'] for c in chats]
    format_strings = ','.join(['%s'] * len(chat_ids))

    cursor.execute(f"SELECT chat_id, user_id FROM user_chats WHERE chat_id IN ({format_strings})", tuple(chat_ids))
    participants = cursor.fetchall()

    participants_map = {}
    for p in participants:
        c_id = p['chat_id']
        if c_id not in participants_map:
            participants_map[c_id] = []
        participants_map[c_id].append(p['user_id'])

    for c in chats:
        c['participant_ids'] = participants_map.get(c['chat_id'], [])

    return chats

def get_participant_ids(conn, chat_id: int):
    cursor = conn.cursor()
    cursor.execute("SELECT user_id FROM user_chats WHERE chat_id = %s", (chat_id,))
    return [row[0] for row in cursor.fetchall()]

def create_chat(conn, chat_data: ChatCreate):
    cursor = conn.cursor()
    try:
        chat_type = 'group' if chat_data.is_group else 'private'
        cursor.execute("INSERT INTO chats (chat_name, chat_type, created_by) VALUES (%s, %s, %s)", (chat_data.name, chat_type, chat_data.created_by))
        chat_id = cursor.lastrowid

        values = [(chat_data.created_by, chat_id, 'admin')]
        for u_id in chat_data.participant_ids:
            if u_id != chat_data.created_by:
                values.append((u_id, chat_id, 'member'))

        cursor.executemany("INSERT INTO user_chats (user_id, chat_id, role) VALUES (%s, %s, %s)", values)

        conn.commit()
        return chat_id
    except Exception as e:
        conn.rollback()
        raise e

def add_chat_member(conn, chat_id: int, user_id: int):
    cursor = conn.cursor()
    cursor.execute("INSERT INTO user_chats (user_id, chat_id) VALUES (%s, %s)", (user_id, chat_id))
    conn.commit()

def remove_participant(conn, chat_id: int, user_id: int):
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM user_chats WHERE chat_id = %s AND user_id = %s", (chat_id, user_id))
        conn.commit()
        return cursor.rowcount > 0
    except Exception:
        conn.rollback()
        return False
    finally:
        cursor.close()

def get_private_chat_between_users(conn, user1_id: int, user2_id: int):
    cursor = conn.cursor(dictionary=True)
    query = """
        SELECT uc1.chat_id
        FROM user_chats uc1
        JOIN user_chats uc2 ON uc1.chat_id = uc2.chat_id
        JOIN chats c ON uc1.chat_id = c.chat_id
        WHERE c.chat_type = 'private'
          AND uc1.user_id = %s
          AND uc2.user_id = %s
    """
    cursor.execute(query, (user1_id, user2_id))
    return cursor.fetchone()

def create_private_chat(conn, creator_id: int, target_id: int):
    cursor = conn.cursor()
    cursor.execute("INSERT INTO chats (chat_name, chat_type, created_by) VALUES (%s, 'private', %s)", (None, creator_id))
    chat_id = cursor.lastrowid

    cursor.executemany("INSERT INTO user_chats (user_id, chat_id) VALUES (%s, %s)", [(creator_id, chat_id), (target_id, chat_id)])
    conn.commit()
    return chat_id

def update_last_message_time(conn, chat_id: int):
    cursor = conn.cursor()
    cursor.execute("UPDATE chats SET last_message_at = CURRENT_TIMESTAMP WHERE chat_id = %s", (chat_id,))
    conn.commit()