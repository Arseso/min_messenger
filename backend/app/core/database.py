import mysql.connector
from app.core.config import db_config

def get_db_connection():
    conn = mysql.connector.connect(**db_config)
    try:
        yield conn
    finally:
        if conn.is_connected():
            conn.close()

def get_db_connection_direct():
    conn = mysql.connector.connect(**db_config)
    if not conn.is_connected():
        raise ConnectionError("Failed to connect to database")
    return conn