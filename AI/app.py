"""
FastAPI AI service for the DACN medical app.

Endpoints (called by the NestJS backend, not by Flutter directly):
  GET  /health           -> liveness + whether the model is loaded
  POST /predict          -> multipart image  -> top-3 skin-disease prediction
  POST /chat             -> {"symptoms": "..."} -> top-3 from Gemini

Run:
  uvicorn app:app --host 0.0.0.0 --port 8000
"""
import os

from dotenv import load_dotenv
from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from PIL import Image
import io

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))

app = FastAPI(title="DACN AI Service", version="1.0.0")

# Lazy singletons so the service can boot even if one part is misconfigured.
_classifier = None


def get_classifier():
    global _classifier
    if _classifier is None:
        from model import SkinDiseaseClassifier
        _classifier = SkinDiseaseClassifier()
    return _classifier


class ChatRequest(BaseModel):
    symptoms: str


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": _classifier is not None}


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File phải là ảnh.")
    try:
        raw = await file.read()
        image = Image.open(io.BytesIO(raw))
    except Exception:
        raise HTTPException(status_code=400, detail="Không đọc được ảnh.")
    try:
        results = get_classifier().predict_topk(image, k=3)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi inference: {e}")
    return {"source": "image-model", "results": results}


@app.post("/chat")
def chat(req: ChatRequest):
    if not req.symptoms or not req.symptoms.strip():
        raise HTTPException(status_code=400, detail="Thiếu mô tả triệu chứng.")
    try:
        from gemini_chat import diagnose_from_symptoms
        results = diagnose_from_symptoms(req.symptoms.strip())
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi gọi Gemini: {e}")
    return {"source": "gemini", "results": results}
