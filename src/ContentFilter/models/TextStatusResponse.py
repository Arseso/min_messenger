from typing import Literal

from pydantic import BaseModel

STATUS = Literal["working", "ready", "error"]

class TextStatusResponse(BaseModel):
    id: str
    status: STATUS
    error_string: str = ""