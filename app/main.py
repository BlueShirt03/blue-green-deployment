import os 

from fastapi import FastAPI

app = FastAPI ()

VERSION = os.getenv("APP_VERSION", "1.0")
ENVIRONMENT = os.getenv("APP_ENV", "blue")


@app.get("/")
def home():
    return{
        "message": "Blue/Green Deployment Demo", 
        "version": VERSION,
        "environment": ENVIRONMENT 
    }


@app.get("/health")
def health():
    return{
        "status": "healthy",
        "version": VERSION
    }