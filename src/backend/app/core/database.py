import mysql.connector
from app.core.config import db_config

def get_db_connection():
    conn = mysql.connector.connect(**db_config)
    try:
        yield conn
    finally:
        conn.close()