from typing import Literal

from pydantic import BaseModel

STATUS = Literal["working", "ready", "error"]

class TextStatusRequest(BaseModel):
    id: str