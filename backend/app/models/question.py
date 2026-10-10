from sqlalchemy import Column, Integer, String, Boolean, Text
from app.database import Base


class FeedbackQuestion(Base):
    __tablename__ = "feedback_questions"

    id = Column(Integer, primary_key=True, index=True)
    question_text = Column(Text, nullable=False)
    category = Column(String(100), nullable=False)
    question_type = Column(String(20), default="rating", nullable=False)
    is_required = Column(Boolean, default=True, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    display_order = Column(Integer, default=1, nullable=False)