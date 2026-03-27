from fastapi import APIRouter, UploadFile, File, HTTPException, Body
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List
from datetime import datetime
import json
import io
import os
import uuid
import tempfile

from database import get_db
from models.audit_model import AuditModel, AuditMetrics

from services.storage_service import storage_service
from services.bias_engine import bias_engine
from services.gemini_service import gemini_service
from services.mitigation_service import mitigation_service

# For PDF generation
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

router = APIRouter(prefix="/audit", tags=["Audit"])

# Input Schemas
class AuditRequest(BaseModel):
    file_id: str
    filename: str
    protected_attributes: List[str]
    domain: str

class ApplyMitigationsRequest(BaseModel):
    mitigations: List[str]



@router.post("")
async def create_audit(req: AuditRequest):
    """
    Runs the full audit pipeline.
    """
    try:
        gcs_path = f"audits/{req.file_id}/{req.filename}"
        
        # 1. Pull file from GCS into pandas
        df = storage_service.download_dataset(gcs_path)
        
        # 2. Run Bias Engine
        metrics_result = bias_engine.compute_metrics(df, req.protected_attributes)
        
        # 3. Gemini Analysis
        ai_result = gemini_service.analyze_metrics(metrics_result["metrics"], req.protected_attributes)
        
        # 4. Save to MongoDB
        audit_doc = AuditModel(
            filename=req.filename,
            domain=req.domain,
            protected_attributes=req.protected_attributes,
            metrics=AuditMetrics(**metrics_result["metrics"]),
            risk_level=metrics_result["risk_level"],
            ai_analysis=ai_result.get("explanation", ""),
            proxy_features=ai_result.get("proxy_features", []),
            status="COMPLETE",
            gcs_file_path=gcs_path
        )
        
        db = get_db()
        await db.audits.insert_one(audit_doc.dict(by_alias=True))
        
        return audit_doc.dict()
        
    except Exception as e:
        print(f"Audit Creation Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{audit_id}/apply")
async def apply_mitigations(audit_id: str, req: ApplyMitigationsRequest):
    """
    Applies mitigations, re-runs audit, saves linked document.
    Saves the mitigated CSV to Supabase as a new file.
    """
    try:
        db = get_db()
        original = await db.audits.find_one({"audit_id": audit_id})
        if not original:
            raise HTTPException(status_code=404, detail="Original audit not found.")
            
        orig_audit = AuditModel(**original)
        
        # 1. Fetch original file
        df = storage_service.download_dataset(orig_audit.gcs_file_path)
        
        # 2. Apply Mitigations
        mod_df = mitigation_service.apply_mitigations(
            df, 
            mitigations=req.mitigations, 
            proxy_features=orig_audit.proxy_features, 
            protected_attributes=orig_audit.protected_attributes
        )
        
        # 3. Re-run metrics on modified df
        metrics_result = bias_engine.compute_metrics(mod_df, orig_audit.protected_attributes)
        ai_result = gemini_service.analyze_metrics(metrics_result["metrics"], orig_audit.protected_attributes)
        
        # 4. Generate new audit ID early so we can use it in the file path
        new_audit_id = str(uuid.uuid4())
        
        # 5. Save mitigated CSV to Supabase Storage
        #    Extract the original file_id from gcs_file_path (audits/{file_id}/{filename})
        path_parts = orig_audit.gcs_file_path.split("/")
        original_file_id = path_parts[1] if len(path_parts) >= 2 else "unknown"
        mitigated_filename = f"mitigated_{new_audit_id[:8]}.csv"
        mitigated_path = f"audits/{original_file_id}/{mitigated_filename}"
        
        try:
            csv_bytes = mod_df.to_csv(index=False).encode("utf-8")
            from services.storage_service import upload_file
            upload_file(csv_bytes, mitigated_path)
        except Exception as upload_err:
            print(f"Warning: Could not upload mitigated CSV: {upload_err}")
            mitigated_path = None  # non-fatal, continue
        
        # 6. Save new audit with mitigated file path
        new_audit = AuditModel(
            audit_id=new_audit_id,
            filename=orig_audit.filename,
            domain=orig_audit.domain,
            protected_attributes=orig_audit.protected_attributes,
            metrics=AuditMetrics(**metrics_result["metrics"]),
            risk_level=metrics_result["risk_level"],
            ai_analysis=ai_result.get("explanation", ""),
            proxy_features=ai_result.get("proxy_features", []),
            mitigations_applied=req.mitigations,
            status="COMPLETE",
            parent_audit_id=audit_id,
            gcs_file_path=orig_audit.gcs_file_path,
            mitigated_file_path=mitigated_path
        )
        await db.audits.insert_one(new_audit.dict(by_alias=True))
        
        return {
            "previous_score": orig_audit.metrics.overall_score if orig_audit.metrics else 0,
            "new_score": new_audit.metrics.overall_score,
            "delta": round(new_audit.metrics.overall_score - (orig_audit.metrics.overall_score if orig_audit.metrics else 0), 3),
            "audit": new_audit.dict()
        }
        
    except Exception as e:
        print(f"Mitigation Application Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{audit_id}/download")
async def download_mitigated(audit_id: str):
    """
    Downloads the mitigated CSV for a given audit.
    Returns 404 if no mitigated file exists.
    """
    try:
        db = get_db()
        doc = await db.audits.find_one({"audit_id": audit_id})
        if not doc:
            raise HTTPException(status_code=404, detail="Audit not found.")
        
        mitigated_path = doc.get("mitigated_file_path")
        if not mitigated_path:
            raise HTTPException(status_code=404, detail="No mitigated file for this audit.")
        
        # Fetch from Supabase
        from services.storage_service import fetch_file
        csv_bytes = fetch_file(mitigated_path)
        
        # Write to temp file and return
        fd, temp_path = tempfile.mkstemp(suffix=".csv")
        os.close(fd)
        with open(temp_path, "wb") as f:
            f.write(csv_bytes)
        
        return FileResponse(
            path=temp_path,
            filename=f"mitigated_{audit_id[:8]}.csv",
            media_type="text/csv"
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"Download Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{audit_id}")
async def get_audit(audit_id: str):
    try:
        db = get_db()
        doc = await db.audits.find_one({"audit_id": audit_id})
        if not doc:
            raise HTTPException(status_code=404, detail="Audit not found.")
        # Remove mongo _id
        if "_id" in doc:
            del doc["_id"]
        return doc
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{audit_id}/export")
async def export_audit(audit_id: str):
    try:
        db = get_db()
        doc = await db.audits.find_one({"audit_id": audit_id})
        if not doc:
            raise HTTPException(status_code=404, detail="Audit not found.")
            
        audit = AuditModel(**doc)
        
        # Check if parent exists for before/after comparison
        parent_score = None
        if audit.parent_audit_id:
            parent = await db.audits.find_one({"audit_id": audit.parent_audit_id})
            if parent and "metrics" in parent and parent["metrics"]:
                parent_score = parent["metrics"].get("overall_score")
        
        # Create PDF
        fd, temp_path = tempfile.mkstemp(suffix=".pdf")
        os.close(fd)
        
        c = canvas.Canvas(temp_path, pagesize=letter)
        c.setFont("Helvetica-Bold", 18)
        c.drawString(50, 750, "FairForge Audit Report")
        
        c.setFont("Helvetica", 12)
        c.drawString(50, 720, f"Audit ID: {audit.audit_id}")
        c.drawString(50, 700, f"Dataset: {audit.filename}")
        c.drawString(50, 680, f"Domain: {audit.domain}")
        c.drawString(50, 660, f"Timestamp: {audit.timestamp.isoformat()}")
        
        c.setFont("Helvetica-Bold", 14)
        c.drawString(50, 620, "Results Summary")
        c.setFont("Helvetica", 12)
        
        score = audit.metrics.overall_score if audit.metrics else "N/A"
        c.drawString(50, 595, f"Overall Score: {score}")
        c.drawString(50, 575, f"Risk Level: {audit.risk_level}")
        
        if parent_score is not None and score != "N/A":
            c.drawString(50, 555, f"Score Change: {parent_score} -> {score}")
            
        y = 525
        if audit.metrics:
            c.drawString(50, y, "- Demographic Parity: " + str(audit.metrics.demographic_parity))
            c.drawString(50, y-20, "- Disparate Impact: " + str(audit.metrics.disparate_impact))
            c.drawString(50, y-40, "- Equalized Odds: " + str(audit.metrics.equalized_odds))
            y -= 70
        else:
            y -= 30
            
        c.setFont("Helvetica-Bold", 14)
        c.drawString(50, y, "AI Analysis")
        c.setFont("Helvetica", 10)
        
        # Simple text wrapping logic
        import textwrap
        text_lines = textwrap.wrap(audit.ai_analysis or "No analysis provided.", width=80)
        y -= 25
        for line in text_lines:
            c.drawString(50, y, line)
            y -= 15
            
        y -= 15
        c.setFont("Helvetica-Bold", 12)
        c.drawString(50, y, "Proxy Features:")
        y -= 20
        c.setFont("Helvetica", 10)
        proxies = ", ".join(audit.proxy_features) if audit.proxy_features else "None identified"
        c.drawString(70, y, proxies)
        
        if audit.mitigations_applied:
            y -= 30
            c.setFont("Helvetica-Bold", 12)
            c.drawString(50, y, "Mitigations Applied:")
            y -= 20
            c.setFont("Helvetica", 10)
            c.drawString(70, y, ", ".join(audit.mitigations_applied))
            
        c.save()
        
        return FileResponse(
            path=temp_path, 
            filename=f"FairForge_Report_{audit.audit_id[:8]}.pdf", 
            media_type='application/pdf'
        )
        
    except Exception as e:
        print(f"Export Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
