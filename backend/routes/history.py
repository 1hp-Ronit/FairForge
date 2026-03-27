from fastapi import APIRouter, Query, HTTPException
from database import get_db
from models.audit_model import AuditModel
from typing import Optional, List

router = APIRouter(prefix="/history", tags=["History"])

@router.get("")
async def get_history(
    domain: Optional[str] = Query(None, description="HIRING, LENDING, HEALTHCARE or OTHER"),
    risk_level: Optional[str] = Query(None, description="HIGH, MED, or LOW"),
    search: Optional[str] = Query(None, description="Search term for filename"),
    page: int = Query(1, ge=1),
    per_page: int = Query(5, ge=1)
):
    try:
        db = get_db()
        filter_query = {}
        
        if domain and domain.upper() != "ALL":
            filter_query["domain"] = domain
            
        if risk_level and risk_level.upper() != "ALL":
            filter_query["risk_level"] = risk_level
            
        if search:
            # Case insensitive regex search on filename
            filter_query["filename"] = {"$regex": search, "$options": "i"}
            
        skip = (page - 1) * per_page
        
        # Determine total documents match filter
        total = await db.audits.count_documents(filter_query)
        
        cursor = db.audits.find(filter_query).sort("timestamp", -1).skip(skip).limit(per_page)
        
        audits = []
        async for doc in cursor:
            # Remove mongo objectid
            if "_id" in doc:
                del doc["_id"]
            audits.append(doc)
            
        return {
            "audits": audits,
            "total": total,
            "page": page,
            "per_page": per_page
        }
        
    except Exception as e:
        import pymongo.errors
        if isinstance(e, pymongo.errors.ServerSelectionTimeoutError) or isinstance(e, pymongo.errors.ConfigurationError):
            print(f"Warning: MongoDB connection failed (using dummy URI?). Returning empty list.")
            return {"audits": [], "total": 0, "page": page, "per_page": per_page}
            
        print(f"History fetch error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
