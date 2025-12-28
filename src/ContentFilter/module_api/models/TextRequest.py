from pydantic import BaseModel, Field

class TextRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Текст для проверки")
    id: str = Field(..., gt=0, description="Уникальный идентификатор")

    # Опционально: пример данных для документации
    class Config:
        json_schema_extra = {
            "example": {
                "id": "12345",
                "text": "Пример текста для обработки" 
            }
        }