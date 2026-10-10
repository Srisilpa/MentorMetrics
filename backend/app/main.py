from fastapi import FastAPI

from app.database import Base, engine
from app import models
from app.routers import auth

app = FastAPI(
    title="MentorMetrics API",
    description="Faculty feedback and analytics system",
    version="1.0.0",
)

# Create database tables
Base.metadata.create_all(bind=engine)

app.include_router(auth.router)


@app.get("/")
def home():
    return {
        "message": "Welcome to MentorMetrics API",
        "status": "running",
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}