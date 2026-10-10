from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app import models
from app.routers import auth, departments, faculty, subjects, feedback

app = FastAPI(
    title="MentorMetrics API",
    description="Faculty Feedback and Analytics System API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Robust CORS configuration for Flutter Web, Android Emulators, and local development
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure tables exist
Base.metadata.create_all(bind=engine)

# Include API Routers
app.include_router(auth.router)
app.include_router(departments.router)
app.include_router(faculty.router)
app.include_router(subjects.router)
app.include_router(feedback.router)


@app.get("/")
def home():
    return {
        "message": "Welcome to MentorMetrics API",
        "description": "Faculty Feedback and Analytics System",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "MentorMetrics API",
        "database": "connected",
    }