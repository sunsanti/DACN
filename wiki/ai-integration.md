---
last_updated: 2026-06-03
tags: [ai, integration, architecture, gemini, pytorch, fastapi]
---

# AI Integration — Đã hiện thực khung *(2026-06-03)*

Luồng AI mô tả trong [[project-report]]: bệnh nhân gửi **ảnh + triệu chứng** → hệ thống
chẩn đoán → tổng hợp **PDF gửi bác sĩ**. Khung đã được build (build/biên dịch sạch);
còn lại là chạy thực tế (cần tạo venv Windows + Gemini key).

## Trạng thái build

| Thành phần | File | Trạng thái |
| --- | --- | --- |
| FastAPI `/predict` (ảnh, Swin V2) | `AI/app.py`, `AI/model.py` | ✅ code xong, `py_compile` OK |
| FastAPI `/chat` (Gemini) | `AI/app.py`, `AI/gemini_chat.py` | ✅ code xong |
| Model weights `.pth` (334MB) | `AI/skin_disease_swinv2_best.pth` | ✅ có sẵn, **gitignored** |
| NestJS `AiModule` | `backend/src/ai/*` | ✅ `npm run build` pass |
| Đăng ký module + ConfigModule | `backend/src/app.module.ts` | ✅ |
| Deps | `@nestjs/config`, `pdfkit`, `@types/multer`, `@types/pdfkit` | ✅ đã cài |

## Còn phải làm để chạy thực tế

1. Tạo lại venv trên Windows (`.venv` hiện tại là của Mac) + `pip install -r AI/requirements.txt`.
2. `cp AI/.env.example AI/.env` và điền **GEMINI_API_KEY mới** (key cũ đã lộ — thu hồi).
3. Chạy 2 process: `uvicorn app:app --port 8000` (trong AI/) + `npm run start:dev` (backend, 3000).
4. ~~Nhúng font TTF tiếng Việt~~ ✅ Đã làm — `ai.service.ts` tự dò Arial (Windows) / DejaVu,
   override bằng `AI_PDF_FONT`. PDF cũng đã **nhúng ảnh bệnh nhân**.
5. (Tùy chọn) Lưu PDF/kết quả gắn vào `appointment` để bác sĩ xem ([[doctor-module]]).

## API đã expose (NestJS, qua `/ai`)

| Method | Path | Body | Mục đích |
| --- | --- | --- | --- |
| POST | `/ai/diagnose-image` | multipart `image` | Top-3 bệnh từ model ảnh |
| POST | `/ai/chat` | JSON `{symptoms}` | Top-3 bệnh từ Gemini |
| POST | `/ai/report` | multipart field `symptoms` (bắt buộc) + `image` (tuỳ chọn) | Triệu chứng, có ảnh thì gộp thêm → **PDF** cho bác sĩ |

NestJS gọi sang Python service tại `AI_SERVICE_URL` (mặc định `http://localhost:8000`).

## Quyết định kiến trúc

- **Model chẩn đoán ảnh** (`.pth`, PyTorch): chạy trong **một Python service riêng
  (FastAPI/Flask)**, không nhúng vào NestJS. NestJS gọi sang qua HTTP. *(Lý do: NestJS là
  Node, không chạy `.pth` trực tiếp; giữ nguyên code train, ít rủi ro nhất.)*
- **Chatbox**: dùng **Gemini API**, gọi **qua NestJS (proxy)**, không gọi thẳng từ Flutter.
  API key giấu trong `.env` của backend. *(Đã có model train cho ảnh; chatbox chưa có dataset
  nên tạm dùng Gemini.)*

## Sơ đồ luồng

```
Flutter ──(ảnh + triệu chứng)──► NestJS backend
                                   │
                                   ├─HTTP─► ai-service (FastAPI)  → model.pth → nhãn bệnh
                                   ├─HTTP─► Gemini API            → phân tích triệu chứng
                                   │
                                   └─ gộp kết quả → sinh PDF → gắn vào appointment / gửi bác sĩ
```

## Bố cục thư mục dự kiến

```
DACN/
├── ai-service/              # MỚI — Python FastAPI
│   ├── main.py              # endpoint POST /predict (ảnh → nhãn bệnh)
│   ├── model.py             # class kiến trúc nn.Module + load weights
│   ├── model.pth            # trọng số đã train (cân nhắc Git LFS nếu >50MB)
│   ├── labels.json          # danh sách nhãn bệnh + input size
│   └── requirements.txt     # torch, torchvision, pillow, fastapi, uvicorn...
├── backend/src/ai/          # MỚI — NestJS module
│   ├── ai.module.ts
│   ├── ai.controller.ts     # /ai/diagnose-image, /ai/chat, /ai/report
│   └── ai.service.ts        # gọi ai-service + Gemini, tổng hợp PDF
└── frontend/                # Flutter (gọi /ai/* của backend)
```

## Việc cần làm khi hiện thực

1. Dựng `ai-service/` FastAPI: load `.pth`, `/predict` nhận ảnh → trả `{label, confidence}`.
2. Tạo `AiModule` trong NestJS, đăng ký vào `app.module.ts` ([[project-architecture]]).
3. `ai.service.ts`: gọi ai-service (chẩn đoán ảnh) + Gemini (chatbox); đọc key từ
   `process.env.GEMINI_API_KEY`.
4. Sinh PDF (vd `pdfkit`/`pdfmake` trong Node) từ kết quả gộp; liên kết với `appointment`
   để bác sĩ xem ([[doctor-module]]).
5. Thêm `@nestjs/config` để quản lý `.env` (đồng thời chuyển credential DB ra env — [[known-issues]]).

## Ràng buộc / lưu ý

- **Không commit API key** Gemini; dùng `.env` (đã gitignore) hoặc biến môi trường.
- Cần chạy **2 process**: NestJS (3000) + ai-service (vd 8000). Cập nhật hướng dẫn run.
- Tiền xử lý ảnh ở Python phải đúng như lúc train (resize, normalize) — lấy từ code inference gốc.

Liên quan: [[project-report]] · [[project-architecture]] · [[api-routes]] · [[doctor-module]] · [[known-issues]]
