from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.student import Student
from app.models.department import Department
from app.schemas.auth import LoginRequest, LoginResponse, RegisterRequest, UserResponse
from app.core.security import verify_password, get_password_hash, create_access_token
from app.dependencies.auth import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email.strip().lower()).first()

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account is inactive. Please contact the administrator.",
        )

    token = create_access_token(
        data={
            "sub": str(user.id),
            "role": user.role,
            "email": user.email,
        }
    )

    return LoginResponse(
        access_token=token,
        token_type="bearer",
        role=user.role,
        name=user.name,
        id=user.id,
        email=user.email,
    )


@router.post("/register", response_model=UserResponse)
def register_student(payload: RegisterRequest, db: Session = Depends(get_db)):
    email = payload.email.strip().lower()

    existing = db.query(User).filter(User.email == email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email address already exists",
        )

    if payload.roll_number:
        existing_roll = db.query(Student).filter(Student.roll_number == payload.roll_number.strip()).first()
        if existing_roll:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A student with this roll number already exists",
            )

    new_user = User(
        name=payload.name.strip(),
        email=email,
        password_hash=get_password_hash(payload.password),
        role="student",  # Always defaults to student; users cannot self-escalate to admin
        is_active=True,
    )
    db.add(new_user)
    db.flush()

    new_student = Student(
        user_id=new_user.id,
        roll_number=payload.roll_number.strip() if payload.roll_number else None,
        department_id=payload.department_id,
        academic_year=payload.academic_year.strip() if payload.academic_year else "2026-27",
    )
    db.add(new_student)
    db.commit()
    db.refresh(new_user)

    dept_name = None
    if new_student.department_id:
        dept = db.query(Department).filter(Department.id == new_student.department_id).first()
        if dept:
            dept_name = dept.name

    return UserResponse(
        id=new_user.id,
        name=new_user.name,
        email=new_user.email,
        role=new_user.role,
        is_active=new_user.is_active,
        created_at=new_user.created_at,
        roll_number=new_student.roll_number,
        department_id=new_student.department_id,
        department_name=dept_name,
        academic_year=new_student.academic_year,
    )


@router.get("/me", response_model=UserResponse)
def get_me(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    roll_number = None
    dept_id = None
    dept_name = None
    academic_year = None

    if user.student_profile:
        roll_number = user.student_profile.roll_number
        dept_id = user.student_profile.department_id
        academic_year = user.student_profile.academic_year
        if dept_id:
            dept = db.query(Department).filter(Department.id == dept_id).first()
            if dept:
                dept_name = dept.name

    return UserResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        role=user.role,
        is_active=user.is_active,
        created_at=user.created_at,
        roll_number=roll_number,
        department_id=dept_id,
        department_name=dept_name,
        academic_year=academic_year,
    )