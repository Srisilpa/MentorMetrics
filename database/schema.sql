-- MentorMetrics: Faculty Feedback and Analytics System
-- Complete MySQL 8 Database Schema

CREATE DATABASE IF NOT EXISTS mentormetrics;
USE mentormetrics;

-- 1. Departments
CREATE TABLE IF NOT EXISTS departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Users (Authentication & Accounts)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL, -- 'admin' or 'student'
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_email (email),
    INDEX idx_user_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Faculty
CREATE TABLE IF NOT EXISTS faculty (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    department_id INT NULL,
    designation VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_faculty_dept (department_id),
    CONSTRAINT fk_faculty_department FOREIGN KEY (department_id) 
        REFERENCES departments(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Students
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    roll_number VARCHAR(50) UNIQUE NULL,
    department_id INT NULL,
    academic_year VARCHAR(20) NULL,
    CONSTRAINT fk_student_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_student_department FOREIGN KEY (department_id) 
        REFERENCES departments(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Subjects
CREATE TABLE IF NOT EXISTS subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subject_code VARCHAR(50) NOT NULL UNIQUE,
    subject_name VARCHAR(150) NOT NULL,
    department_id INT NULL,
    semester VARCHAR(20) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_subject_dept (department_id),
    CONSTRAINT fk_subject_department FOREIGN KEY (department_id) 
        REFERENCES departments(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Faculty-Subject Assignments
CREATE TABLE IF NOT EXISTS faculty_subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    faculty_id INT NOT NULL,
    subject_id INT NOT NULL,
    academic_year VARCHAR(20) NULL,
    UNIQUE KEY uq_fac_sub (faculty_id, subject_id),
    CONSTRAINT fk_facsub_faculty FOREIGN KEY (faculty_id) 
        REFERENCES faculty(id) ON DELETE CASCADE,
    CONSTRAINT fk_facsub_subject FOREIGN KEY (subject_id) 
        REFERENCES subjects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Feedback Questions
CREATE TABLE IF NOT EXISTS feedback_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_text TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    question_type VARCHAR(20) NOT NULL DEFAULT 'rating',
    is_required TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    display_order INT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Feedback Submissions
CREATE TABLE IF NOT EXISTS feedback_submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    faculty_id INT NOT NULL,
    subject_id INT NULL,
    subject_name VARCHAR(150) NULL,
    teaching_quality INT NOT NULL DEFAULT 5,
    subject_knowledge INT NOT NULL DEFAULT 5,
    communication INT NOT NULL DEFAULT 5,
    punctuality INT NOT NULL DEFAULT 5,
    overall_satisfaction INT NOT NULL DEFAULT 5,
    rating INT NOT NULL DEFAULT 5,
    comments TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_fb_student (student_id),
    INDEX idx_fb_faculty (faculty_id),
    INDEX idx_fb_subject (subject_id),
    CONSTRAINT fk_submission_student FOREIGN KEY (student_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_submission_faculty FOREIGN KEY (faculty_id) 
        REFERENCES faculty(id) ON DELETE CASCADE,
    CONSTRAINT fk_submission_subject FOREIGN KEY (subject_id) 
        REFERENCES subjects(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Feedback Answers (Itemized question answers)
CREATE TABLE IF NOT EXISTS feedback_answers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    submission_id INT NOT NULL,
    question_id INT NULL,
    rating INT NULL,
    answer_text TEXT NULL,
    CONSTRAINT fk_answer_submission FOREIGN KEY (submission_id) 
        REFERENCES feedback_submissions(id) ON DELETE CASCADE,
    CONSTRAINT fk_answer_question FOREIGN KEY (question_id) 
        REFERENCES feedback_questions(id) ON DELETE SET NULL,
    CONSTRAINT uq_submission_question UNIQUE (submission_id, question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Feedback Records (Legacy compatibility table)
CREATE TABLE IF NOT EXISTS feedback_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    faculty_id INT NOT NULL,
    subject VARCHAR(150) NOT NULL,
    rating INT NOT NULL,
    comments TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_records_student FOREIGN KEY (student_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_records_faculty FOREIGN KEY (faculty_id) 
        REFERENCES faculty(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
