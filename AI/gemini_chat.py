"""
Chatbox symptom analysis via Gemini.
Reads the API key from the GEMINI_API_KEY environment variable (never hard-code it).
Returns top-3 candidate diseases (constrained to the 22 trained classes) as JSON.
"""
import os
import json

from google import genai
from google.genai import types

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CLASSES_TXT = os.path.join(BASE_DIR, "classes.txt")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")


def _load_classes():
    if os.path.exists(CLASSES_TXT):
        with open(CLASSES_TXT, "r", encoding="utf-8") as f:
            return [line.strip() for line in f if line.strip()]
    return []


def _client():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY chưa được set trong môi trường (.env).")
    return genai.Client(api_key=api_key)


def diagnose_from_symptoms(symptoms: str):
    """Return a list of top-3 {disease, confidence, reason} from a symptom description."""
    classes = _load_classes()
    class_list = ", ".join(classes) if classes else "danh sách bệnh da liễu phổ biến"

    prompt = f"""
Bệnh nhân mô tả triệu chứng: "{symptoms}".
Chỉ được chọn trong danh sách {len(classes)} bệnh da liễu sau: [{class_list}].
Hãy đưa ra chẩn đoán Top 3 bệnh có khả năng cao nhất, trả về JSON là một MẢNG gồm
các object có các trường: "disease" (đúng tên trong danh sách), "confidence" (số thực 0..1),
"reason" (giải thích ngắn bằng tiếng Việt).
""".strip()

    client = _client()
    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(response_mime_type="application/json"),
    )

    try:
        data = json.loads(response.text)
    except (json.JSONDecodeError, TypeError):
        # Fall back to raw text if Gemini returned non-JSON.
        return {"raw": response.text}

    # Accept either a bare array or an object wrapping the array.
    if isinstance(data, dict):
        for key in ("results", "diseases", "top3", "data"):
            if isinstance(data.get(key), list):
                return data[key]
    return data
