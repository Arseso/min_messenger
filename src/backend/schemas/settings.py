from pydantic import BaseModel


class SettingsResponse(BaseModel):
    private_profile: bool
    allow_invites: bool


class UpdateSettingsRequest(BaseModel):
    private_profile: bool | None = None
    allow_invites: bool | None = None
