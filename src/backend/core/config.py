import os

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
SESSION_TTL = 60 * 60 * 24 * 7      
MESSAGE_TTL = 60 * 60 * 24          
PRESENCE_TTL = 60                   
INSTANCE_ID = os.getenv("INSTANCE_ID", "instance-1")
