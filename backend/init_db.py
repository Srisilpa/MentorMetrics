import os
import pymysql
from dotenv import load_dotenv
from pwdlib import PasswordHash

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "mentormetrics")

password_hasher = PasswordHash.recommended()

def migrate_and_seed():
    print("Connecting to MySQL...")
    conn = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        charset="utf8mb4"
    )
    cur = conn.cursor()

    cur.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` DEFAULT CHARACTER SET utf8mb4;")
    conn.select_db(DB_NAME)

    print("Checking and applying tables...")

    # 1. Departments table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `departments` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `name` VARCHAR(100) NOT NULL UNIQUE,
        `description` TEXT NULL,
        `is_active` TINYINT(1) NOT NULL DEFAULT 1,
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    # 2. Users table check & columns
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `users` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `name` VARCHAR(100) NOT NULL,
        `email` VARCHAR(150) NOT NULL UNIQUE,
        `password_hash` VARCHAR(255) NOT NULL,
        `role` VARCHAR(20) NOT NULL,
        `is_active` TINYINT(1) NOT NULL DEFAULT 1,
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    # Check if created_at exists in users
    cur.execute("SHOW COLUMNS FROM `users` LIKE 'created_at';")
    if not cur.fetchone():
        cur.execute("ALTER TABLE `users` ADD COLUMN `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP;")

    # 3. Faculty table check & columns
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `faculty` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `name` VARCHAR(100) NOT NULL,
        `department` VARCHAR(100) NOT NULL,
        `department_id` INT NULL,
        `designation` VARCHAR(100) NOT NULL,
        `email` VARCHAR(150) UNIQUE NULL,
        `is_active` TINYINT(1) NOT NULL DEFAULT 1,
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    cur.execute("SHOW COLUMNS FROM `faculty` LIKE 'department_id';")
    if not cur.fetchone():
        cur.execute("ALTER TABLE `faculty` ADD COLUMN `department_id` INT NULL AFTER `department`;")
    cur.execute("SHOW COLUMNS FROM `faculty` LIKE 'created_at';")
    if not cur.fetchone():
        cur.execute("ALTER TABLE `faculty` ADD COLUMN `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP;")

    # 4. Students table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `students` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `user_id` INT NOT NULL UNIQUE,
        `roll_number` VARCHAR(50) UNIQUE NULL,
        `department_id` INT NULL,
        `academic_year` VARCHAR(20) NULL,
        CONSTRAINT `fk_student_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    # 5. Subjects table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `subjects` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `subject_code` VARCHAR(50) NOT NULL UNIQUE,
        `subject_name` VARCHAR(150) NOT NULL,
        `department_id` INT NULL,
        `semester` VARCHAR(20) NULL,
        `is_active` TINYINT(1) NOT NULL DEFAULT 1,
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    # 6. Faculty-Subjects assignment table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `faculty_subjects` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `faculty_id` INT NOT NULL,
        `subject_id` INT NOT NULL,
        `academic_year` VARCHAR(20) NULL,
        UNIQUE KEY `uq_fac_sub` (`faculty_id`, `subject_id`),
        CONSTRAINT `fk_facsub_faculty` FOREIGN KEY (`faculty_id`) REFERENCES `faculty`(`id`) ON DELETE CASCADE,
        CONSTRAINT `fk_facsub_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    # 7. Feedback questions table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `feedback_questions` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `question_text` TEXT NOT NULL,
        `category` VARCHAR(100) NOT NULL,
        `question_type` VARCHAR(20) NOT NULL DEFAULT 'rating',
        `is_required` TINYINT(1) NOT NULL DEFAULT 1,
        `is_active` TINYINT(1) NOT NULL DEFAULT 1,
        `display_order` INT NOT NULL DEFAULT 1
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    # 8. Feedback submissions table check & update columns
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `feedback_submissions` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `faculty_id` INT NOT NULL,
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    # Add required columns if missing
    sub_cols = {
        'student_id': "INT NOT NULL DEFAULT 1 AFTER `id`",
        'subject_id': "INT NULL AFTER `faculty_id`",
        'subject_name': "VARCHAR(150) NULL AFTER `subject_id`",
        'teaching_quality': "INT NOT NULL DEFAULT 5",
        'subject_knowledge': "INT NOT NULL DEFAULT 5",
        'communication': "INT NOT NULL DEFAULT 5",
        'punctuality': "INT NOT NULL DEFAULT 5",
        'overall_satisfaction': "INT NOT NULL DEFAULT 5",
        'rating': "INT NOT NULL DEFAULT 5",
        'comments': "TEXT NULL",
    }
    for col_name, col_def in sub_cols.items():
        cur.execute(f"SHOW COLUMNS FROM `feedback_submissions` LIKE '{col_name}';")
        if not cur.fetchone():
            cur.execute(f"ALTER TABLE `feedback_submissions` ADD COLUMN `{col_name}` {col_def};")

    # 9. Feedback Answers table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `feedback_answers` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `submission_id` INT NOT NULL,
        `question_id` INT NULL,
        `rating` INT NULL,
        `answer_text` TEXT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    # 10. Feedback Records table (legacy table)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS `feedback_records` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `student_id` INT NOT NULL,
        `faculty_id` INT NOT NULL,
        `subject` VARCHAR(150) NOT NULL,
        `rating` INT NOT NULL,
        `comments` TEXT NULL,
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)

    conn.commit()
    print("Database structure verified and updated successfully.")

    # Now Seed Data if tables are empty
    # Seed Departments
    cur.execute("SELECT count(*) FROM `departments`;")
    if cur.fetchone()[0] == 0:
        print("Seeding departments...")
        depts = [
            ("Computer Science & Engineering", "Department of Computer Science and Engineering"),
            ("Information Technology", "Department of Information Technology"),
            ("Electronics & Communication", "Department of Electronics and Communication Engineering"),
            ("Artificial Intelligence & Data Science", "Department of AI and Data Science"),
        ]
        cur.executemany("INSERT INTO `departments` (`name`, `description`) VALUES (%s, %s);", depts)
        conn.commit()

    # Get department map
    cur.execute("SELECT id, name FROM `departments`;")
    dept_map = {name: d_id for d_id, name in cur.fetchall()}

    # Ensure admin user
    cur.execute("SELECT id FROM `users` WHERE `email` = 'vinay123@gmail.com';")
    admin_row = cur.fetchone()
    if not admin_row:
        print("Creating admin user...")
        cur.execute(
            "INSERT INTO `users` (`name`, `email`, `password_hash`, `role`, `is_active`) VALUES (%s, %s, %s, %s, %s);",
            ("Vinay Admin", "vinay123@gmail.com", password_hasher.hash("vinay123"), "admin", 1)
        )
        conn.commit()

    # Ensure student user
    cur.execute("SELECT id FROM `users` WHERE `email` = 'roshi@gmail.com';")
    student_row = cur.fetchone()
    if not student_row:
        print("Creating student user...")
        cur.execute(
            "INSERT INTO `users` (`name`, `email`, `password_hash`, `role`, `is_active`) VALUES (%s, %s, %s, %s, %s);",
            ("Roshitha", "roshi@gmail.com", password_hasher.hash("roshi123"), "student", 1)
        )
        conn.commit()
        cur.execute("SELECT id FROM `users` WHERE `email` = 'roshi@gmail.com';")
        student_id = cur.fetchone()[0]
    else:
        student_id = student_row[0]

    # Ensure student profile in students table
    cur.execute("SELECT id FROM `students` WHERE `user_id` = %s;", (student_id,))
    if not cur.fetchone():
        cse_id = dept_map.get("Computer Science & Engineering")
        cur.execute(
            "INSERT INTO `students` (`user_id`, `roll_number`, `department_id`, `academic_year`) VALUES (%s, %s, %s, %s);",
            (student_id, "21B91A0501", cse_id, "2023-2027")
        )
        conn.commit()

    # Seed Feedback Questions
    cur.execute("SELECT count(*) FROM `feedback_questions`;")
    if cur.fetchone()[0] == 0:
        print("Seeding feedback questions...")
        questions = [
            ("Teaching Quality", "How effectively does the faculty explain fundamental concepts and resolve student questions?", "rating", 1, 1, 1),
            ("Subject Knowledge", "How thoroughly does the faculty master the curriculum and provide practical real-world insights?", "rating", 1, 1, 2),
            ("Communication", "How clear, audible, engaging, and approachable is the faculty's communication style?", "rating", 1, 1, 3),
            ("Punctuality", "How consistent, punctual, and well-organized is the faculty in conducting lectures and laboratory sessions?", "rating", 1, 1, 4),
            ("Overall Satisfaction", "What is your overall satisfaction with the faculty's instruction, course pacing, and mentorship?", "rating", 1, 1, 5),
        ]
        cur.executemany(
            "INSERT INTO `feedback_questions` (`category`, `question_text`, `question_type`, `is_required`, `is_active`, `display_order`) VALUES (%s, %s, %s, %s, %s, %s);",
            questions
        )
        conn.commit()

    # Seed Faculty
    cur.execute("SELECT count(*) FROM `faculty`;")
    if cur.fetchone()[0] == 0:
        print("Seeding faculty...")
        cse_id = dept_map.get("Computer Science & Engineering")
        it_id = dept_map.get("Information Technology")
        ece_id = dept_map.get("Electronics & Communication")
        aids_id = dept_map.get("Artificial Intelligence & Data Science")

        fac_list = [
            ("Dr. Ramesh Kumar", "Computer Science & Engineering", cse_id, "Professor & HOD", "ramesh.cse@mentormetrics.edu", 1),
            ("Dr. Priya Sharma", "Computer Science & Engineering", cse_id, "Associate Professor", "priya.cse@mentormetrics.edu", 1),
            ("Mr. Suresh Babu", "Computer Science & Engineering", cse_id, "Assistant Professor", "suresh.cse@mentormetrics.edu", 1),
            ("Dr. Anita Rao", "Information Technology", it_id, "Professor", "anita.it@mentormetrics.edu", 1),
            ("Mr. Karthik Reddy", "Information Technology", it_id, "Assistant Professor", "karthik.it@mentormetrics.edu", 1),
            ("Dr. Rajesh Verma", "Electronics & Communication", ece_id, "Professor", "rajesh.ece@mentormetrics.edu", 1),
            ("Mrs. Swapna Latha", "Electronics & Communication", ece_id, "Assistant Professor", "swapna.ece@mentormetrics.edu", 1),
            ("Dr. Arvind Narayanan", "Artificial Intelligence & Data Science", aids_id, "Associate Professor", "arvind.aids@mentormetrics.edu", 1),
        ]
        cur.executemany(
            "INSERT INTO `faculty` (`name`, `department`, `department_id`, `designation`, `email`, `is_active`) VALUES (%s, %s, %s, %s, %s, %s);",
            fac_list
        )
        conn.commit()

    # Seed Subjects
    cur.execute("SELECT count(*) FROM `subjects`;")
    if cur.fetchone()[0] == 0:
        print("Seeding subjects...")
        cse_id = dept_map.get("Computer Science & Engineering")
        it_id = dept_map.get("Information Technology")
        ece_id = dept_map.get("Electronics & Communication")
        aids_id = dept_map.get("Artificial Intelligence & Data Science")

        sub_list = [
            ("CS301", "Advanced Data Structures & Algorithms", cse_id, "Semester 5", 1),
            ("CS302", "Database Management Systems", cse_id, "Semester 5", 1),
            ("CS303", "Operating Systems & System Architecture", cse_id, "Semester 5", 1),
            ("CS304", "Full-Stack Web Technologies", cse_id, "Semester 5", 1),
            ("IT401", "Cloud Computing & DevOps", it_id, "Semester 7", 1),
            ("IT402", "Software Engineering & Agile Methodologies", it_id, "Semester 7", 1),
            ("EC201", "Digital Signal Processing", ece_id, "Semester 4", 1),
            ("EC202", "Microprocessors & Embedded Systems", ece_id, "Semester 4", 1),
            ("AI301", "Machine Learning & Pattern Recognition", aids_id, "Semester 6", 1),
            ("AI302", "Deep Learning & Computer Vision", aids_id, "Semester 6", 1),
        ]
        cur.executemany(
            "INSERT INTO `subjects` (`subject_code`, `subject_name`, `department_id`, `semester`, `is_active`) VALUES (%s, %s, %s, %s, %s);",
            sub_list
        )
        conn.commit()

    # Seed Faculty-Subject mappings
    cur.execute("SELECT count(*) FROM `faculty_subjects`;")
    if cur.fetchone()[0] == 0:
        print("Mapping faculty to subjects...")
        cur.execute("SELECT id, name FROM `faculty`;")
        fac_by_name = {name: f_id for f_id, name in cur.fetchall()}
        cur.execute("SELECT id, subject_code FROM `subjects`;")
        sub_by_code = {code: s_id for s_id, code in cur.fetchall()}

        mappings = [
            (fac_by_name["Dr. Ramesh Kumar"], sub_by_code["CS302"], "2026-27"),
            (fac_by_name["Dr. Ramesh Kumar"], sub_by_code["CS304"], "2026-27"),
            (fac_by_name["Dr. Priya Sharma"], sub_by_code["CS301"], "2026-27"),
            (fac_by_name["Mr. Suresh Babu"], sub_by_code["CS303"], "2026-27"),
            (fac_by_name["Dr. Anita Rao"], sub_by_code["IT401"], "2026-27"),
            (fac_by_name["Mr. Karthik Reddy"], sub_by_code["IT402"], "2026-27"),
            (fac_by_name["Dr. Rajesh Verma"], sub_by_code["EC201"], "2026-27"),
            (fac_by_name["Mrs. Swapna Latha"], sub_by_code["EC202"], "2026-27"),
            (fac_by_name["Dr. Arvind Narayanan"], sub_by_code["AI301"], "2026-27"),
            (fac_by_name["Dr. Arvind Narayanan"], sub_by_code["AI302"], "2026-27"),
        ]
        cur.executemany(
            "INSERT IGNORE INTO `faculty_subjects` (`faculty_id`, `subject_id`, `academic_year`) VALUES (%s, %s, %s);",
            mappings
        )
        conn.commit()

    # Seed initial feedback records for realistic analytics
    cur.execute("SELECT count(*) FROM `feedback_submissions`;")
    if cur.fetchone()[0] == 0:
        print("Seeding realistic feedback records...")
        cur.execute("SELECT id, name FROM `faculty`;")
        fac_by_name = {name: f_id for f_id, name in cur.fetchall()}
        cur.execute("SELECT id, subject_code, subject_name FROM `subjects`;")
        sub_map = {code: (s_id, name) for s_id, code, name in cur.fetchall()}

        sample_submissions = [
            # Dr. Ramesh Kumar - CS302
            (student_id, fac_by_name["Dr. Ramesh Kumar"], sub_map["CS302"][0], sub_map["CS302"][1], 5, 5, 5, 4, 5, 5, "Outstanding professor! Concepts of SQL indexing and normalization were explained clearly."),
            (student_id, fac_by_name["Dr. Ramesh Kumar"], sub_map["CS304"][0], sub_map["CS304"][1], 5, 4, 4, 5, 4, 4, "Great practical demonstrations during laboratory sessions."),
            # Dr. Priya Sharma - CS301
            (student_id, fac_by_name["Dr. Priya Sharma"], sub_map["CS301"][0], sub_map["CS301"][1], 5, 5, 5, 5, 5, 5, "Exceptional clarity in Data Structures. Trees and Graphs problems were solved step-by-step."),
            (student_id, fac_by_name["Dr. Priya Sharma"], sub_map["CS301"][0], sub_map["CS301"][1], 4, 5, 4, 4, 4, 4, "Very knowledgeable and always available during mentor hours."),
            # Mr. Suresh Babu - CS303
            (student_id, fac_by_name["Mr. Suresh Babu"], sub_map["CS303"][0], sub_map["CS303"][1], 4, 4, 4, 4, 4, 4, "Good coverage of OS threads and CPU scheduling algorithms."),
            (student_id, fac_by_name["Mr. Suresh Babu"], sub_map["CS303"][0], sub_map["CS303"][1], 3, 3, 3, 4, 3, 3, "Punctual and follows syllabus systematically."),
            # Dr. Anita Rao - IT401
            (student_id, fac_by_name["Dr. Anita Rao"], sub_map["IT401"][0], sub_map["IT401"][1], 5, 5, 5, 5, 5, 5, "Inspiring teaching style with industry case studies in cloud computing."),
            # Dr. Rajesh Verma - EC201
            (student_id, fac_by_name["Dr. Rajesh Verma"], sub_map["EC201"][0], sub_map["EC201"][1], 4, 4, 4, 4, 4, 4, "Fourier transforms and filtering concepts were very well structured."),
            # Dr. Arvind Narayanan - AI301
            (student_id, fac_by_name["Dr. Arvind Narayanan"], sub_map["AI301"][0], sub_map["AI301"][1], 5, 5, 5, 5, 5, 5, "Superb insights into neural networks and machine learning mathematics!"),
        ]

        for sub in sample_submissions:
            cur.execute("""
            INSERT INTO `feedback_submissions` 
            (`student_id`, `faculty_id`, `subject_id`, `subject_name`, `teaching_quality`, `subject_knowledge`, `communication`, `punctuality`, `overall_satisfaction`, `rating`, `comments`, `created_at`)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW());
            """, sub)
            sub_id = cur.lastrowid

            # Also sync into feedback_records
            cur.execute("""
            INSERT INTO `feedback_records` (`student_id`, `faculty_id`, `subject`, `rating`, `comments`, `created_at`)
            VALUES (%s, %s, %s, %s, %s, NOW());
            """, (sub[0], sub[1], sub[3], sub[9], sub[10]))

            # Also add to feedback_answers for each of the 5 categories
            cur.execute("SELECT id, display_order FROM `feedback_questions` ORDER BY `display_order`;")
            questions_rows = cur.fetchall()
            ratings = [sub[4], sub[5], sub[6], sub[7], sub[8]]
            for idx, q_row in enumerate(questions_rows):
                q_id = q_row[0]
                q_rating = ratings[idx] if idx < len(ratings) else sub[9]
                cur.execute("""
                INSERT INTO `feedback_answers` (`submission_id`, `question_id`, `rating`, `answer_text`)
                VALUES (%s, %s, %s, %s);
                """, (sub_id, q_id, q_rating, None))

        conn.commit()
        print(f"Seeded {len(sample_submissions)} feedback submissions.")

    cur.close()
    conn.close()
    print("Database initialization and migration completed successfully!")

if __name__ == "__main__":
    migrate_and_seed()
