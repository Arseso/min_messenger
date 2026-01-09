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
    REDIS_PWD: str = os.getenv("REDIS_PWD")


if __name__ == "__main__":
    print(Settings.SERVER_HOST)
    print(Settings.SERVER_PORT)