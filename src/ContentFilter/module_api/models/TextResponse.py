from typing import Literal
from pydantic import BaseModel

VERDICT = Literal["OK", "SPAM", "TOXIC"]

class TextResponse(BaseModel):
    id: str
    verdict: VERDICT