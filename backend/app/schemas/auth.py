from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    name: str
    id: int
    email: str


class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    roll_number: Optional[str] = Field(default=None, max_length=50)
    department_id: Optional[int] = None
    academic_year: Optional[str] = Field(default="2026-27", max_length=20)


class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str
    is_active: bool
    created_at: Optional[datetime] = None
    roll_number: Optional[str] = None
    department_id: Optional[int] = None
    department_name: Optional[str] = None
    academic_year: Optional[str] = None

    class Config:
        from_attributes = True
