import os
from dotenv import load_dotenv

if not load_dotenv():
    raise ValueError(".env file didn't loaded")

class Settings:
    
    # server settings
    SERVER_HOST: str = os.getenv("SERVER_HOST")
    SERVER_PORT: int = int(os.getenv("SERVER_PORT"))

    # model settings
    MODEL_REPO: str = os.getenv("NN_HUGGINGFACE_REPOS")

    # redis settings
    REDIS_HOST: str = os.getenv("REDIS_HOST")
    REDIS_PORT: int = int(os.getenv("REDIS_PORT"))
    REDIS_USR: str = os.getenv("REDIS_USR")
    REDIS_PWD: str = os.getenv("REDIS_PWD")
    
    # rabbitmq settings
    RABBITMQ_HOST: str  = os.getenv("RABBITMQ_HOST")
    RABBITMQ_PORT: int = int(os.getenv("RABBITMQ_PORT"))
    RABBITMQ_USR: str = os.getenv("RABBITMQ_USR")
    RABBITMQ_PWD: str = os.getenv("RABBITMQ_PWD")