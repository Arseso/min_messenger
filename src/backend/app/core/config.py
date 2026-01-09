import os
from dotenv import load_dotenv
if not load_dotenv():
    raise ValueError(".env file didn't loaded")

db_config = {
    'host': os.getenv('DB_HOST', '127.0.0.1'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'root'),
    'database': os.getenv('DB_NAME', 'messenger'),
    'port': int(os.getenv('DB_PORT', 3306))
}