from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# Load environment variables FIRST before internal modules
load_dotenv()

from services.storage_service import storage_service
from routes import audit, history

app = FastAPI(
    title="FairForge ML Bias Audit Backend",
    description="Backend API for FairForge running locally",
    version="1.0.0"
)

# CORS configuration to allow all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
# We construct the routers in the routes/ directory
app.include_router(audit.router)
app.include_router(history.router)

@app.get("/")
async def root():
    return {"message": "FairForge API is running"}

@app.post("/upload", tags=["Upload"])
async def upload_file(file: UploadFile = File(...)):
    """
    Accepts CSV/JSON, uploads to Storage, returns headers.
    This is mounted at the root /upload as requested.
    """
    if not (file.filename.endswith(".csv") or file.filename.endswith(".json")):
        raise HTTPException(status_code=400, detail="Only CSV or JSON files are allowed.")
        
    try:
        content = await file.read()
        result = storage_service.upload_dataset(content, file.filename)
        return result
    except Exception as e:
        print(f"Upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
