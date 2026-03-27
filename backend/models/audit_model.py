from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import uuid

class AuditMetrics(BaseModel):
    demographic_parity: float
    disparate_impact: float
    equalized_odds: float
    overall_score: float

class AuditModel(BaseModel):
    audit_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    filename: str
    domain: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    protected_attributes: List[str]
    metrics: Optional[AuditMetrics] = None
    risk_level: Optional[str] = None
    ai_analysis: Optional[str] = None
    proxy_features: List[str] = Field(default_factory=list)
    mitigations_applied: List[str] = Field(default_factory=list)
    status: str = "FAILED" # Default to FAILED, mark COMPLETE on success
    parent_audit_id: Optional[str] = None
    gcs_file_path: str

    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "audit_id": "123e4567-e89b-12d3-a456-426614174000",
                "filename": "hiring_data.csv",
                "domain": "HIRING",
                "timestamp": "2023-10-12T07:20:50.52Z",
                "protected_attributes": ["gender", "race"],
                "metrics": {
                    "demographic_parity": 0.85,
                    "disparate_impact": 0.72,
                    "equalized_odds": 0.90,
                    "overall_score": 0.82
                },
                "risk_level": "LOW",
                "ai_analysis": "The model exhibits slight disparate impact on minority groups...",
                "proxy_features": ["zip_code", "neighborhood"],
                "mitigations_applied": ["pre", "in"],
                "status": "COMPLETE",
                "parent_audit_id": None,
                "gcs_file_path": "audits/123e4567-e89b-12d3-a456-426614174000/hiring_data.csv"
            }
        }
