from sqlalchemy import Column, Integer, String, Boolean
from app.database import Base


class Faculty(Base):
    __tablename__ = "faculty"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    department = Column(String(100), nullable=False)
    designation = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)