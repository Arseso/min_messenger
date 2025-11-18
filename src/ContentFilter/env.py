from dotenv import load_dotenv

load_dotenv()

class Settings:
    
    # server settings
    SERVER_HOST: str = os.getenv("SERVER_HOST")
    SERVER_PORT: int = int(os.getenv("SERVER_PORT"))