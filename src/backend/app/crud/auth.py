from app.models.schemas import UserCreate

def create_user(conn, user: UserCreate):
    cursor = conn.cursor()
    cursor.execute("INSERT INTO users (username, password_hash) VALUES (%s, %s)", (user.username, user.password))
    conn.commit()

def get_user_by_credentials(conn, username: str, password: str):
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT user_id, username, avatar_url FROM users WHERE username=%s AND password_hash=%s", (username, password))
    return cursor.fetchone()