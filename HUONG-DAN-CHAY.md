# Hướng dẫn chạy DACN và mở Swagger

Ứng dụng gồm 4 phần chạy riêng:

| Phần | Thư mục | Cổng | Ghi chú |
| --- | --- | --- | --- |
| PostgreSQL | Docker (`my-postgres`) | `5432` | DB `dacn_db`. pgAdmin ở `http://localhost:5050` (`my-pgadmin`) |
| Backend API (NestJS) | `backend/` | `3000` | Swagger: `http://localhost:3000/api` |
| Dịch vụ AI (FastAPI) | `AI/` | `8000` | Chỉ backend gọi; app Flutter không gọi trực tiếp |
| App (Flutter) | `frontend/` | (tuỳ thiết bị) | Bệnh nhân, bác sĩ, admin |

## 1. Cần cài sẵn

- Node.js 18+ (máy hiện dùng v24)
- Flutter SDK (`flutter doctor` không báo lỗi cho thiết bị bạn định chạy)
- Python 3.10+ (cho dịch vụ AI)
- Docker (chạy PostgreSQL)

## 2. Database

1. Bật container PostgreSQL:
   ```bash
   docker start my-postgres          # lần đầu đã tạo container thì chỉ cần start
   ```
2. Tạo database `dacn_db` (pgAdmin hoặc lệnh dưới), **chỉ làm lần đầu**:
   ```bash
   docker exec -it my-postgres psql -U postgres -c "CREATE DATABASE dacn_db;"
   ```
3. Dựng bảng **lần đầu**: chạy `backend/schema.sql` trong pgAdmin (Query Tool, chọn DB `dacn_db`), rồi chạy migration để thêm các bảng mới:
   ```bash
   cd backend
   npm run typeorm migration:run
   ```
   Mỗi khi kéo code mới về, chạy lại `npm run typeorm migration:run` (an toàn, chỉ chạy migration chưa áp dụng).

> Muốn xoá sạch dữ liệu để demo lại: `npx ts-node src/reset-db.ts` (trong `backend/`). **Xoá toàn bộ dữ liệu**, giữ lại admin `admin@dacn.local` / `Admin@123`, 3 mẫu ca trực và danh bạ BHYT.

## 3. Backend + AI

```bash
cd backend
npm install                 # lần đầu
cp .env.example .env        # lần đầu, rồi sửa giá trị (xem bảng dưới)
```

Biến quan trọng trong `backend/.env`:

| Biến | Ý nghĩa |
| --- | --- |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | Kết nối PostgreSQL (mặc định `localhost:5432`, `postgres` / `123456`, `dacn_db`) |
| `JWT_SECRET`, `JWT_EXPIRES` | Ký token đăng nhập |
| `AI_SERVICE_URL` | Mặc định `http://localhost:8000` |
| `EXAM_FEE`, `EXAM_FEE_BHYT_COVERED` | Phí khám cố định, phí khám có được BHYT trả không |
| `PAYMENT_BANK_BIN`, `PAYMENT_BANK_NAME`, `PAYMENT_ACCOUNT_NO`, `PAYMENT_ACCOUNT_NAME` | Tài khoản nhận tiền khi bệnh nhân quét VietQR |
| `SEPAY_API_KEY` | Khoá xác thực webhook SePay (tự báo tiền về) |

Dịch vụ AI, **lần đầu**:

```bash
cd AI
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env        # điền GEMINI_API_KEY
```

File model `AI/skin_disease_swinv2_best.pth` không có trong git, phải chép vào tay.

**Chạy hằng ngày** (một lệnh chạy cả AI và API):

```bash
cd backend
npm run start:dev
```

Chạy riêng từng phần nếu cần:

```bash
npm run start:backend       # chỉ API (tự reload khi sửa code)
npm start                   # chỉ API, ép múi giờ Asia/Ho_Chi_Minh, không reload
npm run start:ai            # chỉ dịch vụ AI
```

API chạy xong khi log in ra `Nest application successfully started`. Kiểm tra nhanh: mở `http://localhost:3000/api`.

## 4. Mở Swagger (tài liệu + thử API)

1. Chạy backend (mục 3).
2. Mở trình duyệt: **`http://localhost:3000/api`**.
   - File OpenAPI dạng JSON: `http://localhost:3000/api-json` (import được vào Postman).
   - Từ máy khác cùng mạng LAN: `http://<IP-máy-chạy-backend>:3000/api`.
3. **Đăng nhập để gọi API cần quyền:** hầu hết API đều cần JWT.
   1. Mở nhóm **auth** → `POST /auth/login` → **Try it out**.
   2. Nhập body, ví dụ tài khoản admin:
      ```json
      { "email": "admin@dacn.local", "password": "Admin@123" }
      ```
   3. **Execute**, rồi copy giá trị `accessToken` trong response.
   4. Bấm nút **Authorize** (ổ khoá, góc trên bên phải), dán token vào ô **value** (không cần gõ chữ `Bearer`), bấm **Authorize** rồi **Close**.
   5. Giờ các API khác gọi được theo quyền của tài khoản vừa đăng nhập (admin / bác sĩ / bệnh nhân).
4. Đổi vai trò: đăng nhập tài khoản khác, rồi **Authorize → Logout** và dán token mới.

**Tạo bệnh nhân thử trong Swagger:** `POST /auth/register` (không cần token), gửi JSON:

```json
{
  "email": "benhnhan1@dacn.local", "password": "Test@123", "name": "Hoàng Gia Huy",
  "gender": "male", "age": 27, "birthDate": "1999-09-09",
  "phone": "0900000000", "address": "Huế", "cccd": "079099000555"
}
```

CCCD `079099000555` + ngày sinh `1999-09-09` có trong danh bạ BHYT mẫu (thẻ 80%), nên `GET /patient/me` sẽ trả về `insurance`. Danh bạ mẫu: `079096000222` (1996-03-10, 95%), `048085000333` (1985-11-20, 100%), `001090000444` (1990-01-05, thẻ hết hạn). Mỗi CCCD chỉ đăng ký được một lần.

**Giới hạn của Swagger:**
- Các API gửi **file ảnh** (`POST /auth/register-doctor` bắt buộc ảnh, `POST /news`) chưa có ô chọn file trong Swagger. Hãy dùng app (màn admin) hoặc `curl` / Postman dạng `multipart/form-data`, ví dụ:
  ```bash
  curl -X POST http://localhost:3000/auth/register-doctor \
    -H "Authorization: Bearer <token-admin>" \
    -F email=bacsi1@dacn.local -F password=Test@123 -F name="BS. Minh" -F age=35 \
    -F dateOfBirth=1990-01-01 -F gender=male -F phone=0900000001 -F address="PK 1" \
    -F avatar=@/duong/dan/anh.jpg
  ```
- `POST /payments/sepay-webhook` không dùng JWT mà dùng header `Authorization: Apikey <SEPAY_API_KEY>`. Nút Authorize của Swagger không gửi được header này, nên hãy thử bằng `curl`.

## 5. App Flutter

```bash
cd frontend
flutter pub get             # lần đầu và sau mỗi lần đổi pubspec.yaml
```

| Thiết bị | Lệnh | App gọi API ở |
| --- | --- | --- |
| Trình duyệt Chrome | `flutter run -d chrome` | `http://localhost:3000` |
| Máy ảo Android | `flutter run` (chọn emulator) | `http://10.0.2.2:3000` |
| iOS simulator / macOS | `flutter run` (chọn thiết bị) | `http://localhost:3000` |
| Điện thoại thật | `flutter run --dart-define=API_BASE=http://<IP-LAN-máy-tính>:3000` | IP bạn truyền vào |

Điện thoại thật phải cùng mạng Wi-Fi với máy chạy backend.

Tài khoản để vào app:
- **Admin:** `admin@dacn.local` / `Admin@123`
- **Bệnh nhân:** tự đăng ký trong app (cần CCCD 12 số).
- **Bác sĩ:** admin tạo trong app (menu → Thêm bác sĩ, bắt buộc ảnh đại diện).

Tài khoản demo đang có sẵn trong DB dev (tạo lúc test, **mất nếu chạy `reset-db.ts`**), mật khẩu chung `Test@123`:

| Vai trò | Email | Ghi chú |
| --- | --- | --- |
| Bác sĩ | `demo_doctor_1791095637768@dacn.local` | BS. Nguyễn Minh Anh, có ảnh, có ca trực + lịch hẹn |
| Bệnh nhân | `demo3_bhyt_1791099718751@dacn.local` | Trần Thu Hà, CCCD có BHYT 80%, có lịch đã thanh toán QR |
| Bệnh nhân | `demo3_nobhyt_1791099718751@dacn.local` | Lê Văn Nam, không có BHYT, có lịch chờ admin xác nhận tiền mặt |
| Bệnh nhân | `demo_patient_1791095637768@dacn.local` | Trần Thu Hà (tài khoản cũ, chưa có CCCD → không BHYT) |

## 6. Kiểm tra sau khi sửa code

```bash
cd backend
npm test                    # unit test
npm run test:e2e            # e2e, chạy trên DB dev thật
node test/api-smoke.mjs     # smoke toàn bộ API, cần API (:3000) + AI (:8000) đang chạy

cd ../frontend
flutter analyze
flutter test
```

## 7. Lỗi hay gặp

| Triệu chứng | Cách xử lý |
| --- | --- |
| API báo không kết nối được DB | `docker start my-postgres`, kiểm tra `DB_*` trong `backend/.env` |
| Lỗi `relation ... does not exist` / thiếu cột | Chạy `npm run typeorm migration:run` |
| Gửi ảnh + triệu chứng báo 500 `Lỗi gọi Gemini: 503` | Gemini đang quá tải, thử lại sau; kiểm tra `GEMINI_API_KEY` |
| App web không hiện ảnh / bản build cũ | Tải lại trang bằng Cmd+Shift+R (Flutter web có service worker cache) |
| App Android không gọi được API | Dùng `10.0.2.2` cho máy ảo, IP LAN cho máy thật; backend phải đang chạy |
| Swagger trả 401 | Chưa **Authorize** hoặc token hết hạn → đăng nhập lại và dán token mới |
