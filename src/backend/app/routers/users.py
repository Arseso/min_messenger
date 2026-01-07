from fastapi import APIRouter, HTTPException, Depends
from typing import List
from app.models.schemas import UserResponse
from app.core.database import get_db_connection
from app.crud import user as crud_user

router = APIRouter(tags=["Users"])

@router.get("/users/search/{query}", response_model=List[UserResponse])
def search_users(query: str, conn = Depends(get_db_connection)):
    return crud_user.search_users_by_name(conn, query)

@router.get("/users/{user_id}", response_model=UserResponse)
def get_user_info(user_id: int, conn = Depends(get_db_connection)):
    user = crud_user.get_user_by_id(conn, user_id)
    if user:
        return user
    raise HTTPException(status_code=404, detail="User not found")

@router.post("/profile/update")
def update_profile(user_data: UserResponse, conn = Depends(get_db_connection)):
    existing = crud_user.check_username_exists(conn, user_data.username, user_data.user_id)
    if existing:
        raise HTTPException(status_code=400, detail="Этот никнейм уже занят")

    try:
        crud_user.update_user_profile(conn, user_data.user_id, user_data.username, user_data.avatar_url)
        return {"status": "updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/profile/change_password")
def change_password(data: dict, conn = Depends(get_db_connection)):
    user_id = data.get("user_id")
    old_pwd = str(data.get("old_password", "")).strip()
    new_pwd = str(data.get("new_password", "")).strip()

    if not all([user_id, old_pwd, new_pwd]):
        raise HTTPException(status_code=400, detail="Missing required fields")

    try:
        success = crud_user.verify_and_change_password(conn, int(user_id), old_pwd, new_pwd)
        if not success:
            raise HTTPException(status_code=400, detail="Неверный старый пароль")
        return {"status": "password updated"}
    except ValueError:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))