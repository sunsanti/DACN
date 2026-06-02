# AI Service (FastAPI)

Dịch vụ AI cho app DACN: chẩn đoán ảnh bệnh da liễu (model Swin V2 `.pth`) và
phân tích triệu chứng qua Gemini. Được **NestJS backend gọi** (Flutter không gọi trực tiếp).

## Thành phần

| File | Vai trò |
| --- | --- |
| `app.py` | FastAPI app — endpoint `/health`, `/predict`, `/chat` |
| `model.py` | Load `.pth` (Swin V2 + head FastAI), inference top-3 ảnh |
| `gemini_chat.py` | Gọi Gemini phân tích triệu chứng → top-3 (key từ `.env`) |
| `classes.txt` | 22 nhãn bệnh |
| `skin_disease_swinv2_best.pth` | **Trọng số model (334MB, KHÔNG commit — gitignored)** |
| `interface_top3.py` | Script test gốc (CLI, giữ làm tham khảo) |

## Cài đặt (Windows)

```powershell
cd AI
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt   # torch: xem https://pytorch.org nếu cần bản CUDA
copy .env.example .env            # rồi điền GEMINI_API_KEY
```

> Lưu ý: thư mục `.venv` hiện tại trong repo là của máy Mac — trên Windows phải tạo lại
> bằng lệnh trên.

## Chạy

```powershell
uvicorn app:app --host 0.0.0.0 --port 8000
```

## Endpoint

| Method | Path | Body | Trả về |
| --- | --- | --- | --- |
| GET | `/health` | — | `{status, model_loaded}` |
| POST | `/predict` | multipart `file` = ảnh | `{source, results:[{disease, confidence}]}` |
| POST | `/chat` | JSON `{symptoms}` | `{source, results:[{disease, confidence, reason}]}` |

## Bảo mật

- `GEMINI_API_KEY` chỉ đặt trong `.env` (đã gitignore). **Không** hard-code vào source.
- Key cũ từng nằm trong `test_gemeni.py` đã bị lộ → hãy thu hồi và tạo key mới.
