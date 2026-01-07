import os
import uuid
import shutil
from fastapi import UploadFile

def save_file(file: UploadFile, sub_folder: str) -> str:
    base_dir = f"uploads/{sub_folder}"
    os.makedirs(base_dir, exist_ok=True)

    ext = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    path = f"{base_dir}/{filename}"

    with open(path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return f"/{base_dir}/{filename}"