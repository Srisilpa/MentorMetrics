from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app import models
from app.routers import auth

app = FastAPI(
    title="MentorMetrics API",
    description="Faculty feedback and analytics system",
    version="1.0.0",
)

# Allow requests from Flutter Web
app.add_middleware(
    CORSMiddleware,
allow_origins=[
    "http://localhost:59347",
    "http://127.0.0.1:59347",
],
allow_credentials=True,
allow_methods=["*"],
allow_headers=["*"],
)

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