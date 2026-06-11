import os
from google import genai
from google.genai import types

# API key đọc từ biến môi trường — KHÔNG hard-code key vào source (tránh lộ khi commit).
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    raise SystemExit("Hãy set GEMINI_API_KEY trong môi trường trước khi chạy.")

client = genai.Client(api_key=API_KEY)

# 2. Tạo Prompt ép AI trả về đúng 3 bệnh dạng JSON trong danh sách
prompt = """
Bệnh nhân bị: "Nổi mụn bọc sưng đỏ ở mặt và lưng, đau khi chạm vào".
Dựa vào danh sách 22 bệnh sau: [Acne, Psoriasis, Eczema, Tinea, Vitiligo, Rosacea, Warts, Melanoma, v.v.]
Hãy đưa ra chẩn đoán Top 3 bệnh có khả năng nhất dưới dạng cấu trúc JSON gồm các trường: disease, confidence, reason.
"""

print("Đang gửi yêu cầu tới Gemini...")

# 3. Gọi model 1.5 Flash (bản chuyên xử lý nhanh và miễn phí)
# Đổi từ 'gemini-1.5-flash' sang 'gemini-2.5-flash'
response = client.models.generate_content(
    model='gemini-2.5-flash',  # <--- SỬA CHỖ NÀY
    contents=prompt,
    config=types.GenerateContentConfig(
        response_mime_type="application/json" 
    ),
)

print("\nKết quả từ Gemini:")
print(response.text)