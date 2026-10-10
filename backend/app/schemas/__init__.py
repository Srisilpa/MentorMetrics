from app.schemas.auth import LoginRequest, LoginResponse, RegisterRequest, UserResponse
from app.schemas.department import DepartmentCreate, DepartmentUpdate, DepartmentResponse
from app.schemas.faculty import FacultyCreate, FacultyUpdate, FacultyStatusUpdate, FacultyResponse
from app.schemas.subject import SubjectCreate, SubjectUpdate, SubjectStatusUpdate, SubjectResponse, AssignSubjectRequest
from app.schemas.feedback import FeedbackSubmitRequest, FeedbackSubmitResponse, FeedbackHistoryItem, AnalyticsResponse

__all__ = [
    "LoginRequest",
    "LoginResponse",
    "RegisterRequest",
    "UserResponse",
    "DepartmentCreate",
    "DepartmentUpdate",
    "DepartmentResponse",
    "FacultyCreate",
    "FacultyUpdate",
    "FacultyStatusUpdate",
    "FacultyResponse",
    "SubjectCreate",
    "SubjectUpdate",
    "SubjectStatusUpdate",
    "SubjectResponse",
    "AssignSubjectRequest",
    "FeedbackSubmitRequest",
    "FeedbackSubmitResponse",
    "FeedbackHistoryItem",
    "AnalyticsResponse",
]
