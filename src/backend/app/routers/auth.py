from fastapi import APIRouter, HTTPException, Depends
from app.models.schemas import UserCreate, UserResponse
from app.core.database import get_db_connection
from app.crud import auth as crud_auth

router = APIRouter(tags=["Auth"])

@router.post("/register")
def register(user: UserCreate, conn = Depends(get_db_connection)):
    try:
        crud_auth.create_user(conn, user)
        return {"status": "ok"}
    except Exception as e:
        raise HTTPException(status_code=400, detail="User already exists or error")

@router.post("/login", response_model=UserResponse)
def login(user: UserCreate, conn = Depends(get_db_connection)):
    result = crud_auth.get_user_by_credentials(conn, user.username, user.password)
    if result:
        return result
    raise HTTPException(status_code=401, detail="Invalid credentials")