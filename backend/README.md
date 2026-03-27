# FairForge Backend

This is the FastAPI backend serving as the ML Bias Audit engine for FairForge. It integrates Google Cloud Storage, MongoDB, Fairlearn (for bias metric computation), and Gemini for natural language analysis.

## Requirements

Ensure you are using Python 3.9+ environment.

```bash
cd backend
python -m venv .venv

# On Windows:
.venv\Scripts\activate
# On Mac/Linux:
source .venv/bin/activate

pip install -r requirements.txt
```

## Setup Environment Variables

1. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Fill in the required credentials:
   - `GEMINI_API_KEY`: Your Google Gemini API Key.
   - `MONGODB_URI`: The MongoDB Atlas connection string.
   - `GCS_BUCKET_NAME`: The name of your existing Google Cloud Storage bucket.
   - `GOOGLE_APPLICATION_CREDENTIALS`: Path to your GCP service account JSON file.

*Note: If MongoDB is missing, it will attempt to fallback to a local instance at `mongodb://localhost:27017`.*

## Running the Server

Start the application with uvicorn:

```bash
uvicorn main:app --reload
```

The server will start on `http://127.0.0.1:8000`. Full interactive API docs are available at `http://127.0.0.1:8000/docs`.

## Endpoint Summary

### POST `/audit/upload`
Accepts a generic `multipart/form-data` file. Pushes to GCS and extracts headers to return to the frontend for attribute mapping.

### POST `/audit`
Runs the ML audit. Fetches dataset from GCS, generates predictions if missing, evaluates `demographic_parity`, `disparate_impact`, and `equalized_odds` using Fairlearn. Passes the metrics block payload to Gemini for explainability and proxies, then writes the whole document to MongoDB.

### POST `/audit/{audit_id}/apply`
Takes an array of mitigations (e.g., `["pre", "in"]`), fetches the data, triggers the mitigation strategies (proxy dropping, prediction rebalancing, threshold adjusting) and re-evaluates the pipeline. Saves a linked child record.

### GET `/audit/{audit_id}`
Returns the full JSON structure of a completed audit.

### GET `/audit/{audit_id}/export`
Constructs a styled PDF on the fly outlining the scores, risk level, AI text, specific proxy features, and metrics.

### GET `/history`
Returns a paginated list of audits matching optional `domain` and `risk_level` filters, alongside keyword search querying the JSON representation.
