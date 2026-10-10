from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field


class FeedbackSubmitRequest(BaseModel):
    faculty_id: int
    subject_id: Optional[int] = None
    subject: Optional[str] = None
    teaching_quality: int = Field(default=5, ge=1, le=5)
    subject_knowledge: int = Field(default=5, ge=1, le=5)
    communication: int = Field(default=5, ge=1, le=5)
    punctuality: int = Field(default=5, ge=1, le=5)
    overall_satisfaction: int = Field(default=5, ge=1, le=5)
    rating: Optional[int] = Field(default=None, ge=1, le=5)
    comments: Optional[str] = Field(default="", max_length=2000)


class FeedbackSubmitResponse(BaseModel):
    message: str
    id: int


class FeedbackHistoryItem(BaseModel):
    id: int
    faculty_id: int
    faculty_name: str
    department: str
    designation: str
    subject: str
    subject_id: Optional[int] = None
    teaching_quality: int
    subject_knowledge: int
    communication: int
    punctuality: int
    overall_satisfaction: int
    rating: int
    comments: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class FeedbackRecordDetail(BaseModel):
    id: int
    student_id: int
    student_name: str
    faculty_id: int
    faculty_name: str
    department: str
    subject: str
    subject_id: Optional[int] = None
    teaching_quality: int
    subject_knowledge: int
    communication: int
    punctuality: int
    overall_satisfaction: int
    rating: int
    comments: Optional[str] = None
    created_at: Optional[datetime] = None


class FacultyRatingSummary(BaseModel):
    faculty_id: int
    faculty_name: str
    department: str
    feedback_count: int
    average_rating: float


class SubjectFeedbackSummary(BaseModel):
    subject_id: Optional[int] = None
    subject_code: Optional[str] = None
    subject_name: str
    feedback_count: int
    average_rating: float


class DepartmentFeedbackSummary(BaseModel):
    department: str
    feedback_count: int
    average_rating: float


class TrendItem(BaseModel):
    date: str
    count: int
    average_rating: float


class AnalyticsResponse(BaseModel):
    total_faculty: int
    total_students: int
    total_feedback: int
    average_rating: float
    rating_distribution: Dict[str, int]
    faculty_ratings: List[FacultyRatingSummary]
    subject_counts: List[SubjectFeedbackSummary]
    department_comparison: List[DepartmentFeedbackSummary]
    timeline_trends: List[TrendItem]
    recent_feedback: List[FeedbackRecordDetail]
