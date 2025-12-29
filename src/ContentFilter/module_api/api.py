from fastapi import FastAPI
import uvicorn

from models import TextStatusRequest, TextStatusResponse, TextRequest, TextResponse, Error
from storage import QueueWorker, CacheWorker
from env import Settings

app = FastAPI(title="MIN Messager API", version="1.0.0")
queue = QueueWorker(Settings.REDIS_HOST, Settings.REDIS_PORT, Settings.REDIS_PWD)
cache = CacheWorker(Settings.REDIS_HOST, Settings.REDIS_PORT, Settings.REDIS_PWD)


@app.post("/check/", summary="Отправка сообщения на проверку")
async def process_text(request: TextRequest):
    try:
        if not queue.append(request):
            return Error(error_message="Something went wrong")
        else: 
            return TextStatusResponse(id = request.id, status="working")
    except Exception as e:
        return Error(error_message=str(e))
    

@app.get("/status/", response_model=TextStatusResponse, summary="Проверка статуса работы над сообщением")
async def get_status(request: TextStatusRequest):
    try:
        status = ""
        if not cache.has_key(request.id):
            status = "working"
        else: 
            status = "ready"
        return TextStatusResponse(id = request.id, status = status)
    except Exception as e:
        return Error(error_message=str(e))

@app.get("/verdict/", response_model=TextResponse, summary="Получение вердикта")
async def get_verdict(request: TextStatusRequest):
    try:
        verdict = cache.get(request.id)
        if not verdict:
            return Error(error_message="Verdict not ready yet / Incorrect id")
        else: 
            return verdict
    except Exception as e:
        return Error(error_message=str(e))

@app.get("/")
async def root():
    return {"message": "Text Processing API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

def start():
    uvicorn.run(app, host="localhost", port=8000)

