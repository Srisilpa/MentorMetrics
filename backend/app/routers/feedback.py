import csv
import io
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import Response
from sqlalchemy import func, desc, or_
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.student import Student
from app.models.faculty import Faculty
from app.models.subject import Subject
from app.models.faculty_subject import FacultySubject
from app.models.department import Department
from app.models.question import FeedbackQuestion
from app.models.feedback import FeedbackSubmission, FeedbackAnswer
from app.models.feedback_record import FeedbackRecord
from app.schemas.feedback import (
    FeedbackSubmitRequest,
    FeedbackSubmitResponse,
    FeedbackHistoryItem,
    FeedbackRecordDetail,
    AnalyticsResponse,
    FacultyRatingSummary,
    SubjectFeedbackSummary,
    DepartmentFeedbackSummary,
    TrendItem,
)
from app.dependencies.auth import get_current_user, require_admin, require_student

router = APIRouter(prefix="/feedback", tags=["Feedback"])


@router.get("/faculty")
def list_feedback_faculty(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns active faculty members with their subjects for student feedback selection.
    Compatible with existing frontend /feedback/faculty endpoint.
    """
    faculty_list = (
        db.query(Faculty)
        .filter(Faculty.is_active.is_(True))
        .order_by(Faculty.name)
        .all()
    )

    result = []
    for item in faculty_list:
        dept_name = item.dept_relation.name if item.dept_relation else item.department
        subjects = []
        for fa in item.subject_assignments:
            if fa.subject and fa.subject.is_active:
                subjects.append({
                    "id": fa.subject.id,
                    "subject_code": fa.subject.subject_code,
                    "subject_name": fa.subject.subject_name,
                    "semester": fa.subject.semester,
                })

        result.append({
            "id": item.id,
            "name": item.name,
            "department": dept_name,
            "department_id": item.department_id,
            "designation": item.designation,
            "email": item.email,
            "subjects": subjects,
        })

    return result


@router.post("/submit", response_model=FeedbackSubmitResponse)
def submit_feedback(
    payload: FeedbackSubmitRequest,
    student: User = Depends(require_student),
    db: Session = Depends(get_db),
):
    # Validate faculty
    faculty = db.query(Faculty).filter(
        Faculty.id == payload.faculty_id,
        Faculty.is_active.is_(True),
    ).first()

    if not faculty:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Selected faculty member not found or inactive",
        )

    # Validate subject
    subject_id = payload.subject_id
    subject_name = payload.subject

    if subject_id:
        subject = db.query(Subject).filter(
            Subject.id == subject_id,
            Subject.is_active.is_(True),
        ).first()
        if not subject:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Selected subject not found or inactive",
            )
        subject_name = subject.subject_name

        # Validate faculty-subject assignment if any assignments exist for this faculty
        has_assignments = db.query(FacultySubject).filter(
            FacultySubject.faculty_id == faculty.id
        ).first()

        if has_assignments:
            is_assigned = db.query(FacultySubject).filter(
                FacultySubject.faculty_id == faculty.id,
                FacultySubject.subject_id == subject_id,
            ).first()
            if not is_assigned:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Subject '{subject.subject_name}' is not assigned to faculty '{faculty.name}'",
                )
    elif subject_name:
        # Lookup by subject name
        subject = db.query(Subject).filter(
            func.lower(Subject.subject_name) == subject_name.strip().lower()
        ).first()
        if subject:
            subject_id = subject.id
            subject_name = subject.subject_name
        else:
            subject_name = subject_name.strip()
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Subject selection is required",
        )

    # Compute overall rating: user rating or average of the 5 metrics
    calc_rating = payload.rating or round(
        (payload.teaching_quality +
         payload.subject_knowledge +
         payload.communication +
         payload.punctuality +
         payload.overall_satisfaction) / 5
    )

    clean_comments = payload.comments.strip() if payload.comments else None

    # Create submission
    submission = FeedbackSubmission(
        student_id=student.id,
        faculty_id=faculty.id,
        subject_id=subject_id,
        subject_name=subject_name,
        teaching_quality=payload.teaching_quality,
        subject_knowledge=payload.subject_knowledge,
        communication=payload.communication,
        punctuality=payload.punctuality,
        overall_satisfaction=payload.overall_satisfaction,
        rating=calc_rating,
        comments=clean_comments,
    )
    db.add(submission)
    db.flush()

    # Also keep legacy FeedbackRecord updated for backward compatibility
    record = FeedbackRecord(
        student_id=student.id,
        faculty_id=faculty.id,
        subject=subject_name or "General",
        rating=calc_rating,
        comments=clean_comments,
    )
    db.add(record)

    # Populate itemized answers from questions
    questions = db.query(FeedbackQuestion).order_by(FeedbackQuestion.display_order).all()
    metric_map = {
        1: payload.teaching_quality,
        2: payload.subject_knowledge,
        3: payload.communication,
        4: payload.punctuality,
        5: payload.overall_satisfaction,
    }
    for q in questions:
        q_rating = metric_map.get(q.display_order, calc_rating)
        answer = FeedbackAnswer(
            submission_id=submission.id,
            question_id=q.id,
            rating=q_rating,
            answer_text=None,
        )
        db.add(answer)

    db.commit()
    db.refresh(submission)

    return FeedbackSubmitResponse(
        message="Thank you! Your feedback has been recorded successfully.",
        id=submission.id,
    )


@router.get("/my", response_model=List[FeedbackHistoryItem])
def get_my_feedback(
    student: User = Depends(require_student),
    db: Session = Depends(get_db),
):
    """
    Returns only the authenticated student's feedback history.
    Protects privacy: never returns other students' feedback.
    """
    submissions = (
        db.query(FeedbackSubmission)
        .filter(FeedbackSubmission.student_id == student.id)
        .order_by(desc(FeedbackSubmission.created_at))
        .all()
    )

    history = []
    for sub in submissions:
        fac = sub.faculty
        fac_name = fac.name if fac else "Unknown Faculty"
        fac_dept = (fac.dept_relation.name if fac and fac.dept_relation else (fac.department if fac else "General"))
        fac_desig = fac.designation if fac else "Faculty"
        sub_title = sub.subject_name or (sub.subject.subject_name if sub.subject else "Subject")

        history.append(FeedbackHistoryItem(
            id=sub.id,
            faculty_id=sub.faculty_id,
            faculty_name=fac_name,
            department=fac_dept,
            designation=fac_desig,
            subject=sub_title,
            subject_id=sub.subject_id,
            teaching_quality=sub.teaching_quality,
            subject_knowledge=sub.subject_knowledge,
            communication=sub.communication,
            punctuality=sub.punctuality,
            overall_satisfaction=sub.overall_satisfaction,
            rating=sub.rating,
            comments=sub.comments,
            created_at=sub.created_at,
        ))

    return history


@router.get("/admin/analytics", response_model=AnalyticsResponse)
def get_admin_analytics(
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """
    Calculates real metrics and chart data across all faculty, subjects, and submissions.
    """
    active_faculty_count = db.query(Faculty).filter(Faculty.is_active.is_(True)).count()
    student_count = db.query(User).filter(User.role == "student", User.is_active.is_(True)).count()
    submissions = db.query(FeedbackSubmission).all()

    total_submissions = len(submissions)
    avg_rating = (
        round(sum(s.rating for s in submissions) / total_submissions, 2)
        if total_submissions > 0
        else 0.0
    )

    # 1. Rating distribution from 1 to 5 stars
    rating_distribution = {
        str(star): sum(1 for s in submissions if s.rating == star)
        for star in range(1, 6)
    }

    # 2. Average rating by faculty member
    faculty_list = db.query(Faculty).filter(Faculty.is_active.is_(True)).all()
    faculty_ratings = []
    for f in faculty_list:
        f_subs = [s for s in submissions if s.faculty_id == f.id]
        f_count = len(f_subs)
        f_avg = round(sum(s.rating for s in f_subs) / f_count, 2) if f_count > 0 else 0.0
        dept_name = f.dept_relation.name if f.dept_relation else f.department
        faculty_ratings.append(FacultyRatingSummary(
            faculty_id=f.id,
            faculty_name=f.name,
            department=dept_name,
            feedback_count=f_count,
            average_rating=f_avg,
        ))
    faculty_ratings.sort(key=lambda x: x.average_rating, reverse=True)

    # 3. Feedback count by subject
    subjects = db.query(Subject).filter(Subject.is_active.is_(True)).all()
    subject_counts = []
    for sub in subjects:
        s_subs = [s for s in submissions if s.subject_id == sub.id or s.subject_name == sub.subject_name]
        s_count = len(s_subs)
        s_avg = round(sum(s.rating for s in s_subs) / s_count, 2) if s_count > 0 else 0.0
        subject_counts.append(SubjectFeedbackSummary(
            subject_id=sub.id,
            subject_code=sub.subject_code,
            subject_name=sub.subject_name,
            feedback_count=s_count,
            average_rating=s_avg,
        ))
    subject_counts.sort(key=lambda x: x.feedback_count, reverse=True)

    # 4. Department-wise feedback comparison
    departments = db.query(Department).filter(Department.is_active.is_(True)).all()
    dept_map = {d.id: d.name for d in departments}
    dept_stats: Dict[str, List[int]] = {}

    for s in submissions:
        dept_name = "General"
        if s.faculty and s.faculty.dept_relation:
            dept_name = s.faculty.dept_relation.name
        elif s.faculty and s.faculty.department:
            dept_name = s.faculty.department
        dept_stats.setdefault(dept_name, []).append(s.rating)

    department_comparison = []
    for dept_name, ratings in dept_stats.items():
        department_comparison.append(DepartmentFeedbackSummary(
            department=dept_name,
            feedback_count=len(ratings),
            average_rating=round(sum(ratings) / len(ratings), 2),
        ))
    department_comparison.sort(key=lambda x: x.feedback_count, reverse=True)

    # 5. Feedback trends over time (group by day)
    trend_dict: Dict[str, List[int]] = {}
    for s in sorted(submissions, key=lambda x: x.created_at or datetime.now()):
        if s.created_at:
            date_str = s.created_at.strftime("%Y-%m-%d")
        else:
            date_str = datetime.now().strftime("%Y-%m-%d")
        trend_dict.setdefault(date_str, []).append(s.rating)

    timeline_trends = [
        TrendItem(
            date=d,
            count=len(rats),
            average_rating=round(sum(rats) / len(rats), 2),
        )
        for d, rats in trend_dict.items()
    ]

    # Recent feedback records (top 15)
    recent_subs = sorted(
        submissions,
        key=lambda x: x.created_at or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True
    )[:15]

    recent_feedback = []
    for s in recent_subs:
        student_display = s.student.name if s.student else "Student"
        fac = s.faculty
        fac_name = fac.name if fac else "Unknown"
        dept_name = fac.dept_relation.name if fac and fac.dept_relation else (fac.department if fac else "General")
        sub_title = s.subject_name or (s.subject.subject_name if s.subject else "Subject")

        recent_feedback.append(FeedbackRecordDetail(
            id=s.id,
            student_id=s.student_id,
            student_name=student_display,
            faculty_id=s.faculty_id,
            faculty_name=fac_name,
            department=dept_name,
            subject=sub_title,
            subject_id=s.subject_id,
            teaching_quality=s.teaching_quality,
            subject_knowledge=s.subject_knowledge,
            communication=s.communication,
            punctuality=s.punctuality,
            overall_satisfaction=s.overall_satisfaction,
            rating=s.rating,
            comments=s.comments,
            created_at=s.created_at,
        ))

    return AnalyticsResponse(
        total_faculty=active_faculty_count,
        total_students=student_count,
        total_feedback=total_submissions,
        average_rating=avg_rating,
        rating_distribution=rating_distribution,
        faculty_ratings=faculty_ratings,
        subject_counts=subject_counts,
        department_comparison=department_comparison,
        timeline_trends=timeline_trends,
        recent_feedback=recent_feedback,
    )


@router.get("/admin/records")
def list_feedback_records(
    faculty_id: Optional[int] = None,
    subject_id: Optional[int] = None,
    department_id: Optional[int] = None,
    rating: Optional[int] = None,
    search: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """
    Search, filter, paginate feedback records for administration.
    """
    query = db.query(FeedbackSubmission).join(Faculty, FeedbackSubmission.faculty_id == Faculty.id)

    if faculty_id:
        query = query.filter(FeedbackSubmission.faculty_id == faculty_id)
    if subject_id:
        query = query.filter(FeedbackSubmission.subject_id == subject_id)
    if department_id:
        query = query.filter(Faculty.department_id == department_id)
    if rating:
        query = query.filter(FeedbackSubmission.rating == rating)
    if search:
        search_pattern = f"%{search.strip()}%"
        query = query.filter(
            or_(
                Faculty.name.ilike(search_pattern),
                FeedbackSubmission.subject_name.ilike(search_pattern),
                FeedbackSubmission.comments.ilike(search_pattern),
            )
        )
    if start_date:
        try:
            sd = datetime.fromisoformat(start_date)
            query = query.filter(FeedbackSubmission.created_at >= sd)
        except ValueError:
            pass
    if end_date:
        try:
            ed = datetime.fromisoformat(end_date)
            query = query.filter(FeedbackSubmission.created_at <= ed)
        except ValueError:
            pass

    total = query.count()
    offset = (page - 1) * page_size
    records = query.order_by(desc(FeedbackSubmission.created_at)).offset(offset).limit(page_size).all()

    items = []
    for s in records:
        fac = s.faculty
        fac_name = fac.name if fac else "Unknown"
        dept_name = fac.dept_relation.name if fac and fac.dept_relation else (fac.department if fac else "General")
        sub_title = s.subject_name or (s.subject.subject_name if s.subject else "Subject")
        student_display = s.student.name if s.student else "Student"

        items.append({
            "id": s.id,
            "student_id": s.student_id,
            "student_name": student_display,
            "faculty_id": s.faculty_id,
            "faculty_name": fac_name,
            "department": dept_name,
            "subject": sub_title,
            "subject_id": s.subject_id,
            "teaching_quality": s.teaching_quality,
            "subject_knowledge": s.subject_knowledge,
            "communication": s.communication,
            "punctuality": s.punctuality,
            "overall_satisfaction": s.overall_satisfaction,
            "rating": s.rating,
            "comments": s.comments,
            "created_at": s.created_at.isoformat() if s.created_at else None,
        })

    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size if total > 0 else 1,
        "items": items,
    }


@router.get("/admin/export")
def export_feedback_csv(
    faculty_id: Optional[int] = None,
    subject_id: Optional[int] = None,
    department_id: Optional[int] = None,
    rating: Optional[int] = None,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """
    Exports filtered feedback records to CSV format.
    Does not expose sensitive information (passwords, tokens, or raw hashes).
    """
    query = db.query(FeedbackSubmission).join(Faculty, FeedbackSubmission.faculty_id == Faculty.id)
    if faculty_id:
        query = query.filter(FeedbackSubmission.faculty_id == faculty_id)
    if subject_id:
        query = query.filter(FeedbackSubmission.subject_id == subject_id)
    if department_id:
        query = query.filter(Faculty.department_id == department_id)
    if rating:
        query = query.filter(FeedbackSubmission.rating == rating)

    records = query.order_by(desc(FeedbackSubmission.created_at)).all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "Feedback ID",
        "Faculty Name",
        "Department",
        "Subject",
        "Overall Rating (1-5)",
        "Teaching Quality",
        "Subject Knowledge",
        "Communication",
        "Punctuality",
        "Satisfaction",
        "Comments",
        "Submission Date",
    ])

    for s in records:
        fac_name = s.faculty.name if s.faculty else "Unknown"
        dept_name = s.faculty.dept_relation.name if s.faculty and s.faculty.dept_relation else (s.faculty.department if s.faculty else "General")
        sub_title = s.subject_name or (s.subject.subject_name if s.subject else "Subject")
        date_str = s.created_at.strftime("%Y-%m-%d %H:%M:%S") if s.created_at else ""

        writer.writerow([
            s.id,
            fac_name,
            dept_name,
            sub_title,
            s.rating,
            s.teaching_quality,
            s.subject_knowledge,
            s.communication,
            s.punctuality,
            s.overall_satisfaction,
            s.comments or "",
            date_str,
        ])

    csv_data = output.getvalue()
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=mentormetrics_feedback_export.csv"},
    )
