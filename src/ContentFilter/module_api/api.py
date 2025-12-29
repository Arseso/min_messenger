from fastapi import FastAPI
import uvicorn

from module_api.models import TextStatusRequest
from module_api.models import TextStatusResponse
from module_api.models import TextRequest
from module_api.models import TextResponse

app = FastAPI(title="MIN Messager API", version="1.0.0")

@app.post("/check/", summary="Обработка текста")
async def process_text(request: TextRequest):
    """
    Обрабатывает переданный текст и возвращает результат обработки.
    
    - **text**: Текст для обработки (минимум 1 символ)
    - **id**: Уникальный числовой идентификатор (больше 0)
    """
    pass

@app.get("/status/", response_model=TextStatusResponse, summary="Обработка текста")
async def get_status(request: TextStatusRequest):
    """
    Обрабатывает переданный текст и возвращает результат обработки.
    - **id**: Уникальный числовой идентификатор (больше 0)
    """
    pass

@app.get("/verdict/", response_model=TextResponse, summary="Обработка текста")
async def get_verdict(request: TextStatusRequest):
    """
    Возвращает вердикт.
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

