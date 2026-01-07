from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from app.core.database import get_db_connection
from app.crud import user as crud_user
from app.core.utils import save_file

router = APIRouter(tags=["Upload"])

@router.post("/upload/avatar/{user_id}")
async def upload_avatar(user_id: int, file: UploadFile = File(...), conn = Depends(get_db_connection)):
    try:
        url = save_file(file, "avatars")
        crud_user.update_user_avatar(conn, user_id, url)
        return {"avatar_url": url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))