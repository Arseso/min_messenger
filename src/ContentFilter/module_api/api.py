from fastapi import FastAPI
import uvicorn

from models.TextRequest import TextRequest
from models.TextResponse import TextResponse


# Создаем экземпляр приложения FastAPI
app = FastAPI(title="MIN Messager API", version="1.0.0")

@app.post("/check/", response_model=TextResponse, summary="Обработка текста")
async def process_text(request: TextRequest):
    """
    Обрабатывает переданный текст и возвращает результат обработки.
    
    - **text**: Текст для обработки (минимум 1 символ)
    - **id**: Уникальный числовой идентификатор (больше 0)
    """
    pass

@app.get("/")
async def root():
    return {"message": "Text Processing API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

def start(host: str, port: int):
    uvicorn.run(app, host="localhost", port=8000)

