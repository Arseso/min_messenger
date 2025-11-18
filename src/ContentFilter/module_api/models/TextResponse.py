from pydantic import BaseModel

class TextResponse(BaseModel):
    id: int
    text: str