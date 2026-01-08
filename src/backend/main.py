from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Cookie
from core.redis import init_redis, get_redis
from services.session_service import get_user_id_by_session
from services.message_service import send_dm
from ws.manager import ws_manager
from core.config import PRESENCE_TTL
from services.friend_service import (
    send_friend_request,
    accept_friend_request,
    FriendError
)
from services.pending_service import (
    deliver_pending_dm,
    deliver_pending_groups
)

from db.base import AsyncSessionLocal
from services.group_service import create_group, add_member, GroupError
from services.group_message_service import send_group_message
from api.auth import router as auth_router
from api.settings import router as settings_router


app = FastAPI()
app.include_router(auth_router)
app.include_router(settings_router)

@app.lifespan("startup")
async def startup():
    await init_redis()


@app.websocket("/ws")
async def websocket_endpoint(
    ws: WebSocket,
    session_id: str | None = Cookie(default=None)
):
    if not session_id:
        await ws.close()
        return

    user_id = await get_user_id_by_session(session_id)
    if not user_id:
        await ws.close()
        return

    await ws_manager.connect(user_id, ws)

    redis = get_redis()
    await redis.setex(f"presence:{user_id}", PRESENCE_TTL, "1")

    await deliver_pending_dm(user_id)
    await deliver_pending_groups(user_id)

    try:
        while True:
            try:
                data = await ws.receive_json()
            except Exception:
                await ws.send_json({
                    "type": "error",
                    "payload": {"code": "INVALID_JSON"}
                })
                continue

            if "type" not in data:
                await ws.send_json({
                    "type": "error",
                    "payload": {"code": "MISSING_TYPE"}
                })
                continue

            try:
                match data.get("type"):
                    case "ping":
                        await redis.setex(f"presence:{user_id}", PRESENCE_TTL, "1")
                        await ws.send_json({"type": "pong"})

                    case "send_message":
                        if "payload" not in data or "to_user_id" not in data.get("payload", {}):
                            await ws.send_json({
                                "type": "error",
                                "payload": {"code": "INVALID_PAYLOAD"}
                            })
                            continue
                        await send_dm(
                            from_user=user_id,
                            to_user=data["payload"]["to_user_id"],
                            payload=data["payload"]
                        )

                    case "ack":
                        if "payload" not in data or "msg_id" not in data.get("payload", {}):
                            await ws.send_json({
                                "type": "error",
                                "payload": {"code": "INVALID_PAYLOAD"}
                            })
                            continue
                        msg_id = data["payload"]["msg_id"]

                        key = f"ack:{msg_id}"
                        await redis.srem(key, user_id)

                        remaining = await redis.scard(key)
                        if remaining == 0:
                            await redis.delete(key)

                    
                    case "friend_request":
                        if "payload" not in data or "to_user_id" not in data.get("payload", {}):
                            await ws.send_json({
                                "type": "error",
                                "payload": {"code": "INVALID_PAYLOAD"}
                            })
                            continue
                        to_user = data["payload"]["to_user_id"]

                        async with AsyncSessionLocal() as db:
                            try:
                                await send_friend_request(db, user_id, to_user)
                            except FriendError as e:
                                await ws.send_json({
                                    "type": "error",
                                    "payload": {"code": e.code}
                                })
                                continue

                        # уведомляем получателя
                        await ws_manager.send_to_user(to_user, {
                            "type": "friend_request_received",
                            "payload": {"from_user_id": user_id}
                        })


                    case "friend_accept":
                        if "payload" not in data or "from_user_id" not in data.get("payload", {}):
                            await ws.send_json({
                                "type": "error",
                                "payload": {"code": "INVALID_PAYLOAD"}
                            })
                            continue
                        from_user = data["payload"]["from_user_id"]

                        async with AsyncSessionLocal() as db:
                            try:
                                await accept_friend_request(db, from_user, user_id)
                            except FriendError as e:
                                await ws.send_json({
                                    "type": "error",
                                    "payload": {"code": e.code}
                                })
                                continue

                        # уведомляем обе стороны
                        await ws_manager.send_to_user(from_user, {
                            "type": "friend_accepted",
                            "payload": {"user_id": user_id}
                        })

                        await ws_manager.send_to_user(user_id, {
                            "type": "friend_accepted",
                            "payload": {"user_id": from_user}
                        })
                    
                    case "create_group":
                        if "payload" not in data or "name" not in data.get("payload", {}):
                            await ws.send_json({
                                "type": "error",
                                "payload": {"code": "INVALID_PAYLOAD"}
                            })
                            continue
                        name = data["payload"]["name"]

                        async with AsyncSessionLocal() as db:
                            try:
                                group_id = await create_group(db, user_id, name)
                            except Exception as e:
                                await ws.send_json({
                                    "type": "error",
                                    "payload": {"code": "GROUP_CREATE_FAILED"}
                                })
                                continue

                        await ws.send_json({
                            "type": "group_created",
                            "payload": {"group_id": group_id}
                        })


                    case "add_group_member":
                        if "payload" not in data or "group_id" not in data.get("payload", {}) or "user_id" not in data.get("payload", {}):
                            await ws.send_json({
                                "type": "error",
                                "payload": {"code": "INVALID_PAYLOAD"}
                            })
                            continue
                        group_id = data["payload"]["group_id"]
                        new_user = data["payload"]["user_id"]

                        async with AsyncSessionLocal() as db:
                            try:
                                await add_member(db, group_id, user_id, new_user)
                            except GroupError as e:
                                await ws.send_json({
                                    "type": "error",
                                    "payload": {"code": e.code}
                                })
                                continue

                        await ws_manager.send_to_user(new_user, {
                            "type": "group_invited",
                            "payload": {"group_id": group_id}
                        })


                    case "send_group_message":
                        if "payload" not in data or "group_id" not in data.get("payload", {}):
                            await ws.send_json({
                                "type": "error",
                                "payload": {"code": "INVALID_PAYLOAD"}
                            })
                            continue
                        await send_group_message(
                            from_user=user_id,
                            group_id=data["payload"]["group_id"],
                            payload=data["payload"]
                        )

                    case _:
                        await ws.send_json({
                            "type": "error",
                            "payload": {"code": "UNKNOWN_TYPE"}
                        })
            except Exception as e:
                await ws.send_json({
                    "type": "error",
                    "payload": {"code": "INTERNAL_ERROR"}
                })

    except WebSocketDisconnect:
        pass
    finally:
        await ws_manager.disconnect(user_id, ws)
