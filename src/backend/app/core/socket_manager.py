from fastapi import WebSocket
import json

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[int, list[WebSocket]] = {}
        self.user_notifications: dict[int, list[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, chat_id: int):
        await websocket.accept()
        if chat_id not in self.active_connections:
            self.active_connections[chat_id] = []
        self.active_connections[chat_id].append(websocket)

    def disconnect(self, websocket: WebSocket, chat_id: int):
        if chat_id in self.active_connections:
            if websocket in self.active_connections[chat_id]:
                self.active_connections[chat_id].remove(websocket)

    async def connect_notifications(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        if user_id not in self.user_notifications:
            self.user_notifications[user_id] = []
        self.user_notifications[user_id].append(websocket)

    def disconnect_notifications(self, websocket: WebSocket, user_id: int):
        if user_id in self.user_notifications:
            if websocket in self.user_notifications[user_id]:
                self.user_notifications[user_id].remove(websocket)

    async def broadcast(self, message: dict, chat_id: int):
        if chat_id in self.active_connections:
            for connection in self.active_connections[chat_id]:
                await connection.send_text(json.dumps(message))

    async def notify_user(self, user_id: int, message: dict):
        sent = False
        if user_id in self.user_notifications:
            for connection in self.user_notifications[user_id]:
                try:
                    await connection.send_text(json.dumps(message))
                    sent = True
                except:
                    pass
        return sent

manager = ConnectionManager()