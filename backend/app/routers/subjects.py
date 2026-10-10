from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.subject import Subject
from app.models.department import Department
from app.schemas.subject import SubjectCreate, SubjectUpdate, SubjectStatusUpdate, SubjectResponse
from app.dependencies.auth import require_admin, get_current_user
from app.models.user import User

router = APIRouter(prefix="/subjects", tags=["Subjects"])


def _format_subject(subject: Subject) -> dict:
    dept_name = subject.department.name if subject.department else None
    return {
        "id": subject.id,
        "subject_code": subject.subject_code,
        "subject_name": subject.subject_name,
        "department_id": subject.department_id,
        "department_name": dept_name,
        "semester": subject.semester,
        "is_active": subject.is_active,
        "created_at": subject.created_at,
    }


@router.get("", response_model=List[SubjectResponse])
def list_subjects(
    active_only: bool = False,
    department_id: Optional[int] = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(Subject)
    if active_only:
        query = query.filter(Subject.is_active.is_(True))
    if department_id:
        query = query.filter(Subject.department_id == department_id)

    subjects = query.order_by(Subject.subject_code).all()
    return [_format_subject(s) for s in subjects]


@router.post("", response_model=SubjectResponse, status_code=status.HTTP_201_CREATED)
def create_subject(
    payload: SubjectCreate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    code = payload.subject_code.strip().upper()
    existing = db.query(Subject).filter(Subject.subject_code == code).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"A subject with code '{code}' already exists",
        )

    if payload.department_id:
        dept = db.query(Department).filter(Department.id == payload.department_id).first()
        if not dept:
            raise HTTPException(status_code=400, detail="Invalid department ID")

    subject = Subject(
        subject_code=code,
        subject_name=payload.subject_name.strip(),
        department_id=payload.department_id,
        semester=payload.semester.strip() if payload.semester else None,
        is_active=True,
    )
    db.add(subject)
    db.commit()
    db.refresh(subject)
    return _format_subject(subject)


@router.get("/{subject_id}", response_model=SubjectResponse)
def get_subject(
    subject_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    return _format_subject(subject)


@router.put("/{subject_id}", response_model=SubjectResponse)
def update_subject(
    subject_id: int,
    payload: SubjectUpdate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    if payload.subject_code:
        code = payload.subject_code.strip().upper()
        existing = db.query(Subject).filter(Subject.subject_code == code, Subject.id != subject_id).first()
        if existing:
            raise HTTPException(status_code=400, detail=f"Subject code '{code}' already in use")
        subject.subject_code = code

    if payload.subject_name:
        subject.subject_name = payload.subject_name.strip()

    if payload.department_id is not None:
        if payload.department_id > 0:
            dept = db.query(Department).filter(Department.id == payload.department_id).first()
            if not dept:
                raise HTTPException(status_code=400, detail="Invalid department ID")
            subject.department_id = payload.department_id
        else:
            subject.department_id = None

    if payload.semester is not None:
        subject.semester = payload.semester.strip() or None

    if payload.is_active is not None:
        subject.is_active = payload.is_active

    db.commit()
    db.refresh(subject)
    return _format_subject(subject)


@router.patch("/{subject_id}/status", response_model=SubjectResponse)
def update_subject_status(
    subject_id: int,
    payload: SubjectStatusUpdate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    subject.is_active = payload.is_active
    db.commit()
    db.refresh(subject)
    return _format_subject(subject)


@router.delete("/{subject_id}")
def delete_subject(
    subject_id: int,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    # Safe deactivation instead of hard cascade delete
    subject.is_active = False
    db.commit()
    return {"message": "Subject deactivated successfully", "id": subject_id}
