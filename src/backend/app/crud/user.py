def search_users_by_name(conn, query: str):
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT user_id, username, avatar_url FROM users WHERE username LIKE %s", (f"%{query}%",))
    return cursor.fetchall()

def get_user_by_id(conn, user_id: int):
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT user_id, username, avatar_url, password_hash FROM users WHERE user_id=%s", (user_id,))
    return cursor.fetchone()

def check_username_exists(conn, username: str, exclude_user_id: int):
    cursor = conn.cursor()
    cursor.execute(
        "SELECT user_id FROM users WHERE username=%s AND user_id != %s", (username, exclude_user_id))
    return cursor.fetchone()

def update_user_profile(conn, user_id: int, username: str, avatar_url: str):
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE users SET username=%s, avatar_url=%s WHERE user_id=%s", (username, avatar_url, user_id))
    conn.commit()

def update_user_avatar(conn, user_id: int, url: str):
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET avatar_url = %s WHERE user_id = %s", (url, user_id))
    conn.commit()

def update_password(conn, user_id: int, new_password: str):
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE users SET password_hash = %s WHERE user_id = %s", (new_password, user_id))
    conn.commit()

def verify_and_change_password(conn, user_id: int, old_pwd: str, new_pwd: str):
    user = get_user_by_id(conn, user_id)
    if not user:
        raise ValueError("Пользователь не найден")

    db_password = str(user['password_hash']).strip()

    if db_password != old_pwd:
        return False

    update_password(conn, user_id, new_pwd)
    return True