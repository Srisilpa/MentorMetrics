from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    DateTime,
    ForeignKey,
    CheckConstraint,
    UniqueConstraint,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class FeedbackSubmission(Base):
    __tablename__ = "feedback_submissions"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    faculty_id = Column(Integer, ForeignKey("faculty.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id", ondelete="SET NULL"), nullable=True, index=True)
    subject_name = Column(String(150), nullable=True)

    teaching_quality = Column(Integer, default=5, nullable=False)
    subject_knowledge = Column(Integer, default=5, nullable=False)
    communication = Column(Integer, default=5, nullable=False)
    punctuality = Column(Integer, default=5, nullable=False)
    overall_satisfaction = Column(Integer, default=5, nullable=False)
    rating = Column(Integer, default=5, nullable=False)
    comments = Column(Text, nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    student = relationship("User")
    faculty = relationship("Faculty", back_populates="submissions")
    subject = relationship("Subject")
    answers = relationship("FeedbackAnswer", back_populates="submission", cascade="all, delete-orphan")


class FeedbackAnswer(Base):
    __tablename__ = "feedback_answers"

    id = Column(Integer, primary_key=True, index=True)
    submission_id = Column(
        Integer,
        ForeignKey("feedback_submissions.id", ondelete="CASCADE"),
        nullable=False,
    )
    question_id = Column(
        Integer,
        ForeignKey("feedback_questions.id", ondelete="SET NULL"),
        nullable=True,
    )
    rating = Column(Integer, nullable=True)
    answer_text = Column(Text, nullable=True)

    submission = relationship("FeedbackSubmission", back_populates="answers")
    question = relationship("FeedbackQuestion")

    __table_args__ = (
        UniqueConstraint(
            "submission_id",
            "question_id",
            name="uq_submission_question",
        ),
        CheckConstraint(
            "rating IS NULL OR rating BETWEEN 1 AND 5",
            name="ck_feedback_rating_range",
        ),
    )