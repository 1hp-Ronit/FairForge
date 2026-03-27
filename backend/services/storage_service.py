import os
import uuid
import io
import pandas as pd
from supabase import create_client, Client

# Initialize Supabase app once at module load
_supabase_url = os.getenv("SUPABASE_URL")
_supabase_key = os.getenv("SUPABASE_KEY")
BUCKET = "fairforge-datasets"

supabase: Client | None = None
if _supabase_url and _supabase_key:
    try:
        supabase = create_client(_supabase_url, _supabase_key)
        print("Supabase initialized successfully.")
    except Exception as e:
        print(f"Warning: Could not initialize Supabase. Error: {e}")
else:
    print("Warning: Supabase credentials missing from environment.")

def upload_file(file_bytes: bytes, destination_path: str) -> str:
    """
    Uploads file bytes to Supabase Storage.
    Returns the public download URL.
    """
    if not supabase:
        raise Exception("Supabase is not configured.")
        
    try:
        supabase.storage.from_(BUCKET).upload(destination_path, file_bytes)
        url = supabase.storage.from_(BUCKET).get_public_url(destination_path)
        return url
    except Exception as e:
        print(f"Supabase Upload Error: {e}")
        raise

def fetch_file(file_path: str) -> bytes:
    """
    Fetches a file from Supabase Storage.
    Returns raw file bytes.
    """
    if not supabase:
        raise Exception("Supabase is not configured.")
        
    try:
        response = supabase.storage.from_(BUCKET).download(file_path)
        return response
    except Exception as e:
        print(f"Supabase Fetch Error: {e}")
        raise

class StorageService:
    """
    Wrapper class keeping the original interface used by routes/audit.py.
    Internally delegates to the upload_file / fetch_file functions above.
    """

    def upload_dataset(self, file_content: bytes, filename: str) -> dict:
        """
        Uploads file to Supabase Storage and extracts column headers.
        Returns dict with file_id, filename, file_size, columns, and gcs_path
        (gcs_path key is kept for backward compatibility — now holds Supabase path).
        """
        file_id = str(uuid.uuid4())
        destination_path = f"audits/{file_id}/{filename}"

        # Human-readable file size
        size_bytes = len(file_content)
        if size_bytes > 1024 * 1024:
            file_size_str = f"{size_bytes / (1024 * 1024):.2f} MB"
        else:
            file_size_str = f"{size_bytes / 1024:.2f} KB"

        # Upload to Supabase
        try:
            upload_file(file_content, destination_path)
        except Exception as e:
            print(f"Upload skipped (Supabase not configured?): {e}")

        # Extract column headers
        columns = []
        try:
            if filename.endswith(".csv"):
                df = pd.read_csv(io.BytesIO(file_content), nrows=5)
                columns = df.columns.tolist()
            elif filename.endswith(".json"):
                df = pd.read_json(io.BytesIO(file_content))
                columns = df.columns.tolist()
        except Exception as e:
            print(f"Error reading headers: {e}")

        return {
            "file_id": file_id,
            "filename": filename,
            "file_size": file_size_str,
            "columns": columns,
            "gcs_path": destination_path,  # kept for backward compat
        }

    def download_dataset(self, gcs_path: str) -> pd.DataFrame:
        """
        Downloads dataset from Supabase Storage into a pandas DataFrame.
        gcs_path is the Supabase Storage object path (e.g. audits/{id}/{filename}).
        """
        content = fetch_file(gcs_path)

        if gcs_path.endswith(".csv"):
            return pd.read_csv(io.BytesIO(content))
        elif gcs_path.endswith(".json"):
            return pd.read_json(io.BytesIO(content))
        else:
            raise ValueError(f"Unsupported file type for path: {gcs_path}")

storage_service = StorageService()
