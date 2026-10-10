from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field


class SubjectBase(BaseModel):
    subject_code: str = Field(min_length=2, max_length=50)
    subject_name: str = Field(min_length=2, max_length=150)
    department_id: Optional[int] = None
    semester: Optional[str] = Field(default=None, max_length=20)


class SubjectCreate(SubjectBase):
    pass


class SubjectUpdate(BaseModel):
    subject_code: Optional[str] = Field(default=None, min_length=2, max_length=50)
    subject_name: Optional[str] = Field(default=None, min_length=2, max_length=150)
    department_id: Optional[int] = None
    semester: Optional[str] = None
    is_active: Optional[bool] = None


class SubjectStatusUpdate(BaseModel):
    is_active: bool


class SubjectResponse(SubjectBase):
    id: int
    is_active: bool
    department_name: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class AssignSubjectRequest(BaseModel):
    subject_id: int
    academic_year: Optional[str] = "2026-27"
