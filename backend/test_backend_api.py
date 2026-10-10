import sys
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def run_tests():
    print("=== RUNNING BACKEND INTEGRATION TESTS ===")

    # 1. Health check
    res = client.get("/health")
    assert res.status_code == 200, f"Health check failed: {res.text}"
    print("[PASS] 1. GET /health -> 200 OK")

    # 2. Invalid login
    res = client.post("/auth/login", json={"email": "wrong@example.com", "password": "wrongpassword123"})
    assert res.status_code == 401, f"Expected 401 for invalid login: {res.status_code}"
    print("[PASS] 2. POST /auth/login (invalid credentials) -> 401 Unauthorized")

    # 3. Admin login
    res = client.post("/auth/login", json={"email": "vinay123@gmail.com", "password": "vinay123"})
    assert res.status_code == 200, f"Admin login failed: {res.text}"
    admin_data = res.json()
    assert admin_data["role"] == "admin"
    admin_token = admin_data["access_token"]
    print(f"[PASS] 3. POST /auth/login (admin) -> 200 OK (role={admin_data['role']})")

    # 4. Student login
    res = client.post("/auth/login", json={"email": "roshi@gmail.com", "password": "roshi123"})
    assert res.status_code == 200, f"Student login failed: {res.text}"
    student_data = res.json()
    assert student_data["role"] == "student"
    student_token = student_data["access_token"]
    print(f"[PASS] 4. POST /auth/login (student) -> 200 OK (role={student_data['role']})")

    student_headers = {"Authorization": f"Bearer {student_token}"}
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 5. GET /auth/me for student
    res = client.get("/auth/me", headers=student_headers)
    assert res.status_code == 200, f"Get /auth/me failed: {res.text}"
    me_data = res.json()
    assert me_data["email"] == "roshi@gmail.com"
    print(f"[PASS] 5. GET /auth/me (student) -> 200 OK (name={me_data['name']})")

    # 6. GET /feedback/faculty
    res = client.get("/feedback/faculty", headers=student_headers)
    assert res.status_code == 200, f"Get faculty failed: {res.text}"
    faculty_list = res.json()
    assert len(faculty_list) > 0, "No faculty returned"
    print(f"[PASS] 6. GET /feedback/faculty -> 200 OK ({len(faculty_list)} faculty members)")

    # 7. GET /subjects
    res = client.get("/subjects", headers=student_headers)
    assert res.status_code == 200, f"Get subjects failed: {res.text}"
    subjects_list = res.json()
    assert len(subjects_list) > 0, "No subjects returned"
    print(f"[PASS] 7. GET /subjects -> 200 OK ({len(subjects_list)} subjects)")

    # 8. Student submits feedback
    target_faculty = faculty_list[0]
    target_faculty_id = target_faculty["id"]
    target_subject_id = target_faculty["subjects"][0]["id"] if target_faculty.get("subjects") else subjects_list[0]["id"]

    submit_payload = {
        "faculty_id": target_faculty_id,
        "subject_id": target_subject_id,
        "teaching_quality": 5,
        "subject_knowledge": 5,
        "communication": 4,
        "punctuality": 5,
        "overall_satisfaction": 5,
        "rating": 5,
        "comments": "Automated verification test submission. Excellent professor!",
    }
    res = client.post("/feedback/submit", json=submit_payload, headers=student_headers)
    assert res.status_code == 200, f"Submit feedback failed: {res.text}"
    submit_res = res.json()
    assert "id" in submit_res
    print(f"[PASS] 8. POST /feedback/submit -> 200 OK (submission_id={submit_res['id']})")

    # 9. GET /feedback/my
    res = client.get("/feedback/my", headers=student_headers)
    assert res.status_code == 200, f"Get my feedback failed: {res.text}"
    my_history = res.json()
    assert len(my_history) > 0
    print(f"[PASS] 9. GET /feedback/my -> 200 OK ({len(my_history)} submissions for student)")

    # 10. Student attempts to access admin analytics (must be 403 Forbidden)
    res = client.get("/feedback/admin/analytics", headers=student_headers)
    assert res.status_code == 403, f"Expected 403 for student accessing admin analytics: {res.status_code}"
    print("[PASS] 10. GET /feedback/admin/analytics with student token -> 403 Forbidden (RBAC works!)")

    # 11. Admin accesses analytics
    res = client.get("/feedback/admin/analytics", headers=admin_headers)
    assert res.status_code == 200, f"Admin analytics failed: {res.text}"
    analytics = res.json()
    assert analytics["total_faculty"] > 0
    assert analytics["total_students"] > 0
    assert analytics["total_feedback"] > 0
    assert analytics["average_rating"] > 0
    assert "5" in analytics["rating_distribution"]
    print(f"[PASS] 11. GET /feedback/admin/analytics -> 200 OK (total_faculty={analytics['total_faculty']}, feedback={analytics['total_feedback']}, avg_rating={analytics['average_rating']})")

    # 12. Admin accesses feedback records
    res = client.get("/feedback/admin/records", headers=admin_headers)
    assert res.status_code == 200, f"Admin records failed: {res.text}"
    records_data = res.json()
    assert records_data["total"] > 0
    print(f"[PASS] 12. GET /feedback/admin/records -> 200 OK ({records_data['total']} total records)")

    # 13. Admin exports CSV
    res = client.get("/feedback/admin/export", headers=admin_headers)
    assert res.status_code == 200, f"CSV export failed: {res.text}"
    assert "text/csv" in res.headers.get("content-type", "")
    assert "Overall Rating" in res.text
    print("[PASS] 13. GET /feedback/admin/export -> 200 OK (CSV generated)")

    # 14. Admin manages faculty CRUD
    new_fac_payload = {
        "name": "Dr. Test Professor",
        "department": "Computer Science & Engineering",
        "designation": "Visiting Professor",
        "email": "test.prof@mentormetrics.edu",
        "is_active": True,
    }
    res = client.post("/faculty", json=new_fac_payload, headers=admin_headers)
    assert res.status_code == 201, f"Create faculty failed: {res.text}"
    new_fac = res.json()
    new_fac_id = new_fac["id"]
    print(f"[PASS] 14. POST /faculty -> 201 Created (id={new_fac_id})")

    # Student cannot create faculty
    res = client.post("/faculty", json=new_fac_payload, headers=student_headers)
    assert res.status_code == 403, f"Expected 403 for student creating faculty: {res.status_code}"
    print("[PASS] 15. POST /faculty with student token -> 403 Forbidden")

    # Update faculty status
    res = client.patch(f"/faculty/{new_fac_id}/status", json={"is_active": False}, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["is_active"] is False
    print("[PASS] 16. PATCH /faculty/{id}/status -> 200 OK (status updated)")

    print("\nALL 16 BACKEND INTEGRATION TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    run_tests()
