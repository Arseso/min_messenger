from fastapi import WebSocket
from typing import Dict, Set
from core.redis import get_redis
from core.config import INSTANCE_ID


class WSManager:
    def __init__(self):
        self.connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, user_id: str, ws: WebSocket):
        await ws.accept()
        self.connections.setdefault(user_id, set()).add(ws)

        redis = get_redis()
        await redis.sadd(f"connections:{user_id}", INSTANCE_ID)

    async def disconnect(self, user_id: str, ws: WebSocket):
        if user_id in self.connections:
            self.connections[user_id].discard(ws)

            if not self.connections[user_id]:
                redis = get_redis()
                await redis.srem(f"connections:{user_id}", INSTANCE_ID)

    async def send_to_user(self, user_id: str, message: dict):
        disconnected = []
        for ws in self.connections.get(user_id, []):
            try:
                await ws.send_json(message)
            except Exception:
                # WebSocket disconnected or error occurred
                disconnected.append(ws)
        
        # Remove disconnected websockets
        if disconnected and user_id in self.connections:
            for ws in disconnected:
                self.connections[user_id].discard(ws)
            
            if not self.connections[user_id]:
                redis = get_redis()
                await redis.srem(f"connections:{user_id}", INSTANCE_ID)


ws_manager = WSManager()
