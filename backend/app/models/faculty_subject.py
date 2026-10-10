from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base


class FacultySubject(Base):
    __tablename__ = "faculty_subjects"

    id = Column(Integer, primary_key=True, index=True)
    faculty_id = Column(Integer, ForeignKey("faculty.id", ondelete="CASCADE"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False)
    academic_year = Column(String(20), nullable=True)

    __table_args__ = (
        UniqueConstraint("faculty_id", "subject_id", name="uq_fac_sub"),
    )

    faculty = relationship("Faculty", back_populates="subject_assignments")
    subject = relationship("Subject", back_populates="faculty_assignments")
