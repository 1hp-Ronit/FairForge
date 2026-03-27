FairForge
Upload data → detect bias → understand why → fix it → verify the fix → document it.

FairForge is an AI-powered algorithmic bias auditing platform. It takes a dataset, runs fairness metrics against protected attributes you define, explains the bias in plain English using Gemini 1.5 Pro, applies mitigation strategies, and exports a compliance-ready audit report — all in one loop.

Table of Contents
Overview
Features
Tech Stack
Architecture
Project Structure
Getting Started
Environment Variables
Audit Pipeline
Fairness Metrics
Mitigation Strategies
API Reference
Firestore Schema
Deployment
Roadmap
Contributing
License
Overview
Bias in ML models is hard to see, harder to explain, and even harder to fix. FairForge makes this accessible:

Upload a CSV or JSON dataset and mark sensitive columns (gender, race, zip code, etc.)
Run an automated audit pipeline — bias metrics computed by Fairlearn, proxy features detected by SHAP, plain-English explanation by Gemini 1.5 Pro
Mitigate — apply reweighting, feature removal, or threshold adjustment strategies
Verify — re-run the audit and compare before vs. after fairness scores
Export — download a structured audit report to Google Docs for compliance handoff
Every audit run is saved to Firestore, giving you a full history of fairness score changes over time.

Features
Drag-and-drop upload — CSV and JSON support, stored to Google Cloud Storage
Automatic column detection — protected attribute tags returned from file headers
4-stage audit pipeline with real-time progress (Firestore-streamed to Flutter)
3 fairness metrics — Demographic Parity, Disparate Impact, Equalized Odds
SHAP-powered proxy detection — surfaces correlated features that act as stand-ins for protected attributes
Gemini 1.5 Pro analysis — plain English explanation of what's causing the bias
Mitigation engine — pre-processing (AIF360 reweighting), in-processing (sklearn model constraints), post-processing (threshold adjustment)
Before vs. after comparison — score delta shown after each re-run
Audit history — filterable by domain, risk level, dataset name; trend charts over time
Google Docs export — structured report delivered to Drive for compliance officers
Tech Stack
Layer	Technology
Frontend	Flutter Web, Material 3
Backend	Python, FastAPI, Google Cloud Run
ML / Bias	Fairlearn, AIF360, SHAP, scikit-learn
AI analysis	Gemini 1.5 Pro via Vertex AI
Data	pandas, NumPy
Storage	Google Cloud Storage (files), Firebase Firestore (audit docs)
Auth	Firebase Authentication (Google OAuth)
Export	Google Docs API
Dev environment	Project IDX, Gemini Code Assist
Dataset	UCI Adult Income Dataset (via Kaggle)
Architecture
┌─────────────────────────────────────────────────┐
│              Flutter Web (frontend)              │
│   New Audit · Results · History · Export         │
│   Firebase Auth · Firestore stream listener      │
└──────────────────────┬──────────────────────────┘
                       │ REST
┌──────────────────────▼──────────────────────────┐
│           FastAPI — Python (Cloud Run)           │
│   /upload · /audit · /mitigate · /export         │
│                  │ writes progress               │
│          ┌───────▼────────┐                      │
│          │    Firestore   │ ◄── Flutter listens  │
│          └───────┬────────┘                      │
│                  │                               │
│   ┌──────────────▼──────────────────────────┐   │
│   │          ML / AI Pipeline               │   │
│   │  pandas → Fairlearn/AIF360 → SHAP →     │   │
│   │  Gemini 1.5 Pro (Vertex AI) → report    │   │
│   └─────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│                 Storage layer                    │
│  GCS (raw files) · Firestore (audit documents)   │
└─────────────────────────────────────────────────┘
Pipeline progress is streamed in real time: FastAPI writes a pipeline_status field to the audit's Firestore document at each stage, and the Flutter StreamBuilder updates the stepper widget without polling.
