from getpass import getpass

from pwdlib import PasswordHash
from sqlalchemy.exc import SQLAlchemyError

from app.database import Base, engine, SessionLocal
from app import models
from app.models.user import User

password_hasher = PasswordHash.recommended()


def create_user(db, role):
    print(f"\n--- Create {role.title()} Account ---")

    name = input("Enter full name: ").strip()
    email = input("Enter email: ").strip().lower()
    password = getpass("Enter password (minimum 8 characters): ")
    confirm_password = getpass("Confirm password: ")

    if not name or not email:
        print("Name and email cannot be empty.")
        return

    if len(password) < 8:
        print("Password must contain at least 8 characters.")
        return

    if password != confirm_password:
        print("Passwords do not match.")
        return

    existing_user = db.query(User).filter(
        User.email == email
    ).first()

    if existing_user:
        print("An account with this email already exists.")
        return

    user = User(
        name=name,
        email=email,
        password_hash=password_hasher.hash(password),
        role=role,
        is_active=True,
    )

    db.add(user)
    db.commit()

    print(f"{role.title()} account created successfully.")
    print(f"Name: {name}")
    print(f"Email: {email}")
    print(f"Role: {role}")


def main():
    # Ensure all imported model tables exist.
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    try:
        create_user(db, "admin")
        create_user(db, "student")
    except SQLAlchemyError as error:
        db.rollback()
        print("\nDatabase error:", error)
        print("Check your database connection and configuration.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
