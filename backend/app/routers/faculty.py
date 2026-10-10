from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.faculty import Faculty
from app.models.department import Department
from app.models.subject import Subject
from app.models.faculty_subject import FacultySubject
from app.schemas.faculty import (
    FacultyCreate,
    FacultyUpdate,
    FacultyStatusUpdate,
    FacultyResponse,
    SubjectSimple,
)
from app.schemas.subject import AssignSubjectRequest
from app.dependencies.auth import require_admin, get_current_user
from app.models.user import User

router = APIRouter(prefix="/faculty", tags=["Faculty"])


def _format_faculty(faculty: Faculty) -> dict:
    subjects = []
    if faculty.subject_assignments:
        for fa in faculty.subject_assignments:
            if fa.subject and fa.subject.is_active:
                subjects.append({
                    "id": fa.subject.id,
                    "subject_code": fa.subject.subject_code,
                    "subject_name": fa.subject.subject_name,
                    "semester": fa.subject.semester,
                })

    dept_name = faculty.department
    if faculty.dept_relation:
        dept_name = faculty.dept_relation.name

    return {
        "id": faculty.id,
        "name": faculty.name,
        "department": dept_name,
        "department_id": faculty.department_id,
        "designation": faculty.designation,
        "email": faculty.email,
        "is_active": faculty.is_active,
        "created_at": faculty.created_at,
        "subjects": subjects,
    }


@router.get("", response_model=List[FacultyResponse])
def list_faculty(
    active_only: bool = False,
    department_id: Optional[int] = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(Faculty)
    if active_only:
        query = query.filter(Faculty.is_active.is_(True))
    if department_id:
        query = query.filter(Faculty.department_id == department_id)

    faculty_list = query.order_by(Faculty.name).all()
    return [_format_faculty(f) for f in faculty_list]


@router.post("", response_model=FacultyResponse, status_code=status.HTTP_201_CREATED)
def create_faculty(
    payload: FacultyCreate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    if payload.email:
        existing = db.query(Faculty).filter(Faculty.email == payload.email.strip().lower()).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Faculty with email '{payload.email}' already exists",
            )

    dept_name = payload.department or "General"
    dept_id = payload.department_id
    if dept_id:
        dept = db.query(Department).filter(Department.id == dept_id).first()
        if dept:
            dept_name = dept.name
    elif payload.department:
        dept = db.query(Department).filter(Department.name == payload.department.strip()).first()
        if dept:
            dept_id = dept.id
            dept_name = dept.name

    faculty = Faculty(
        name=payload.name.strip(),
        department=dept_name,
        department_id=dept_id,
        designation=payload.designation.strip(),
        email=payload.email.strip().lower() if payload.email else None,
        is_active=payload.is_active,
    )
    db.add(faculty)
    db.commit()
    db.refresh(faculty)
    return _format_faculty(faculty)


@router.get("/{faculty_id}", response_model=FacultyResponse)
def get_faculty(
    faculty_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")
    return _format_faculty(faculty)


@router.put("/{faculty_id}", response_model=FacultyResponse)
def update_faculty(
    faculty_id: int,
    payload: FacultyUpdate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")

    if payload.email:
        email = payload.email.strip().lower()
        existing = db.query(Faculty).filter(Faculty.email == email, Faculty.id != faculty_id).first()
        if existing:
            raise HTTPException(status_code=400, detail=f"Email '{email}' is already in use by another faculty member")
        faculty.email = email

    if payload.name:
        faculty.name = payload.name.strip()

    if payload.designation:
        faculty.designation = payload.designation.strip()

    if payload.department_id is not None:
        if payload.department_id > 0:
            dept = db.query(Department).filter(Department.id == payload.department_id).first()
            if not dept:
                raise HTTPException(status_code=400, detail="Invalid department ID")
            faculty.department_id = dept.id
            faculty.department = dept.name
        else:
            faculty.department_id = None

    if payload.department and payload.department_id is None:
        faculty.department = payload.department.strip()

    if payload.is_active is not None:
        faculty.is_active = payload.is_active

    db.commit()
    db.refresh(faculty)
    return _format_faculty(faculty)


@router.patch("/{faculty_id}/status", response_model=FacultyResponse)
def update_faculty_status(
    faculty_id: int,
    payload: FacultyStatusUpdate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")

    faculty.is_active = payload.is_active
    db.commit()
    db.refresh(faculty)
    return _format_faculty(faculty)


@router.delete("/{faculty_id}")
def delete_faculty(
    faculty_id: int,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")

    faculty.is_active = False
    db.commit()
    return {"message": "Faculty member deactivated successfully", "id": faculty_id}


# Faculty - Subject assignments
@router.get("/{faculty_id}/subjects", response_model=List[SubjectSimple])
def get_faculty_subjects(
    faculty_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")

    subjects = []
    for fa in faculty.subject_assignments:
        if fa.subject and fa.subject.is_active:
            subjects.append(fa.subject)
    return subjects


@router.post("/{faculty_id}/subjects")
def assign_subject_to_faculty(
    faculty_id: int,
    payload: AssignSubjectRequest,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")

    subject = db.query(Subject).filter(Subject.id == payload.subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    existing = db.query(FacultySubject).filter(
        FacultySubject.faculty_id == faculty_id,
        FacultySubject.subject_id == payload.subject_id,
    ).first()

    if existing:
        return {"message": "Subject is already assigned to this faculty member"}

    assignment = FacultySubject(
        faculty_id=faculty_id,
        subject_id=payload.subject_id,
        academic_year=payload.academic_year or "2026-27",
    )
    db.add(assignment)
    db.commit()

    return {"message": f"Assigned '{subject.subject_name}' to '{faculty.name}' successfully"}


@router.delete("/{faculty_id}/subjects/{subject_id}")
def unassign_subject_from_faculty(
    faculty_id: int,
    subject_id: int,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    assignment = db.query(FacultySubject).filter(
        FacultySubject.faculty_id == faculty_id,
        FacultySubject.subject_id == subject_id,
    ).first()

    if not assignment:
        raise HTTPException(status_code=404, detail="Subject assignment not found")

    db.delete(assignment)
    db.commit()
    return {"message": "Subject unassigned successfully"}
