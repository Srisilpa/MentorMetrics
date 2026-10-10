from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class SubjectSimple(BaseModel):
    id: int
    subject_code: str
    subject_name: str
    semester: Optional[str] = None

    class Config:
        from_attributes = True


class FacultyBase(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    department: Optional[str] = None
    department_id: Optional[int] = None
    designation: str = Field(min_length=2, max_length=100)
    email: Optional[EmailStr] = None


class FacultyCreate(FacultyBase):
    is_active: bool = True


class FacultyUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=2, max_length=100)
    department: Optional[str] = None
    department_id: Optional[int] = None
    designation: Optional[str] = Field(default=None, min_length=2, max_length=100)
    email: Optional[EmailStr] = None
    is_active: Optional[bool] = None


class FacultyStatusUpdate(BaseModel):
    is_active: bool


class FacultyResponse(BaseModel):
    id: int
    name: str
    department: str
    department_id: Optional[int] = None
    designation: str
    email: Optional[str] = None
    is_active: bool
    created_at: Optional[datetime] = None
    subjects: List[SubjectSimple] = []

    class Config:
        from_attributes = True
