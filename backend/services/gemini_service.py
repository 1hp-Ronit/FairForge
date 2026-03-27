import google.generativeai as genai
import os
import json

class GeminiService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        if self.api_key:
            genai.configure(api_key=self.api_key)
            # Use the model allowed by the current key environment
            self.model = genai.GenerativeModel('models/gemini-2.5-flash')
        else:
            print("Warning: GEMINI_API_KEY missing.")
            self.model = None

    def analyze_metrics(self, metrics_json: dict, attributes: list) -> dict:
        """
        Sends the metrics and attributes to Gemini to generate the plain English report.
        Strict JSON response.
        """
        if not self.model:
            return {
                "explanation": "[Mock] The ML model exhibits correlation bias related to unconfigured proxies.",
                "proxy_features": ["zip_code"],
                "summary": "[Mock] Medium risk due to localized disparate impact."
            }
            
        prompt = f"""You are an ML fairness auditor. Here are bias metrics from a dataset audit:
{json.dumps(metrics_json, indent=2)}
Protected attributes analyzed: {attributes}

Return a JSON object with exactly these fields:
{{
  "explanation": "string (2-3 sentences, plain English, accessible to non-technical reader)",
  "proxy_features": ["list of column names likely acting as proxy discriminators based on standard ML reasoning given these attributes"],
  "summary": "string (one sentence risk summary)"
}}
Return only valid JSON. No markdown blocking. No preamble."""

        try:
            response = self.model.generate_content(
                prompt,
                generation_config=genai.GenerationConfig(
                    response_mime_type="application/json",
                )
            )
            # Try to load the text directly as JSON
            return json.loads(response.text)
        except Exception as e:
            print(f"Gemini Analysis Error: {e}")
            return {
                "explanation": "Failed to generate AI analysis due to API error.",
                "proxy_features": [],
                "summary": "Error analyzing metrics."
            }

gemini_service = GeminiService()
