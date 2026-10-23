# DACN Clinic: đặt lịch khám và chẩn đoán sơ bộ bằng AI

Đồ án chuyên ngành: ứng dụng đặt lịch khám da liễu với 3 vai trò **bệnh nhân**, **bác sĩ** và **admin**. Bệnh nhân gửi ảnh vùng da kèm triệu chứng, AI phân loại bệnh và trả về báo cáo PDF cho bác sĩ tham khảo. Sau buổi khám, hệ thống tự tính tiền, trừ phần **BHYT** chi trả, và cho bệnh nhân thanh toán bằng **tiền mặt** hoặc **VietQR**.

## Tính năng

**Bệnh nhân**
- Đăng ký bằng CCCD. Khi nhập CCCD và ngày sinh, ô "Thẻ BHYT" tự tra và hiện mã thẻ (đã che), mức hưởng, hạn thẻ.
- Trang chủ có tin tức (carousel có mũi tên) và các nút tắt: đặt lịch, lịch hẹn của tôi, chờ thanh toán, hoá đơn đã trả, báo cáo AI, hồ sơ.
- Đặt / dời (1 lần) / huỷ lịch, ghi chú cho bác sĩ.
- Gửi ảnh + triệu chứng cho AI, nhận báo cáo PDF.
- Xem hoá đơn: phí khám, từng dịch vụ, phần BHYT trả, số tiền còn phải trả. Thanh toán tiền mặt hoặc quét VietQR.

**Bác sĩ**
- Trang chủ có thống kê (chờ xác nhận, lịch hôm nay, đã khám) và lối tắt "Ca làm của tôi".
- Xác nhận / từ chối / huỷ (kèm lý do), dời lịch, khám xong (chọn bệnh/dịch vụ để lập hoá đơn), hẹn tái khám, xem báo cáo AI.
- Đăng ký và huỷ ca trực (sáng / chiều / tối).

**Admin**
- Thanh điều hướng 4 mục: Bác sĩ & lương, Thanh toán, Bảng giá, Tin tức.
- Tạo tài khoản bác sĩ, xem giờ làm và lương (giờ × đơn giá).
- Bảng giá bệnh/dịch vụ (đánh dấu mục được BHYT chi trả), quản lý tin tức.
- Xác nhận tiền mặt. Thông báo khi tiền chuyển khoản về (webhook SePay), có badge số chưa đọc.

## Kiến trúc

```
Flutter app  ──HTTP/JWT──►  NestJS API (:3000)  ──►  PostgreSQL (dacn_db)
(frontend/)                 (backend/)          ──►  AI service FastAPI (:8000, AI/)
                                                       ├─ Swin V2 (.pth): phân loại bệnh da
                                                       └─ Gemini: phân tích triệu chứng
```

| Thư mục | Công nghệ | Ghi chú |
|---|---|---|
| `frontend/` | Flutter 3, Provider, dio | Một app cho cả 3 vai, tự chuyển màn theo vai sau khi đăng nhập |
| `backend/` | NestJS 11, TypeORM 0.3, PostgreSQL | Swagger ở `/api`. Mọi route cần JWT trừ đăng ký, đăng nhập, tra BHYT |
| `AI/` | FastAPI, PyTorch, Gemini | Chỉ backend gọi; app không gọi trực tiếp |

## Chạy dự án

### 1. Cần cài

Node.js 18+, Flutter SDK, Python 3.10+, Docker (cho PostgreSQL).

### 2. Database

```bash
docker run -d --name my-postgres -e POSTGRES_PASSWORD=123456 -p 5432:5432 postgres:16   # lần đầu
docker exec -it my-postgres psql -U postgres -c "CREATE DATABASE dacn_db;"              # lần đầu
```

Chạy `backend/schema.sql` vào DB `dacn_db` (pgAdmin → Query Tool), rồi chạy migration:

```bash
cd backend
npm install
cp .env.example .env              # sửa DB_*, JWT_SECRET, tài khoản nhận VietQR...
npm run typeorm migration:run     # chạy lại mỗi khi kéo code mới
```

### 3. Dịch vụ AI

```bash
cd AI
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env              # điền GEMINI_API_KEY
```

File model `AI/skin_disease_swinv2_best.pth` không nằm trong git, cần chép vào tay.

### 4. Bật backend + AI

```bash
cd backend
npm run start:dev                 # chạy cả AI (:8000) và API (:3000)
```

Mở `http://localhost:3000/api` để xem Swagger. Đăng nhập bằng `POST /auth/login`, rồi bấm **Authorize** và dán `accessToken` vào.

### 5. App Flutter

```bash
cd frontend
flutter pub get
```

| Chạy trên | Lệnh |
|---|---|
| Chrome | `flutter run -d chrome` |
| Máy ảo iOS | `open -a Simulator` rồi `flutter run` |
| Máy ảo Android | `flutter run` (app tự gọi `10.0.2.2:3000`) |
| Điện thoại thật (cùng Wi-Fi) | `flutter run --dart-define=API_BASE=http://<IP-LAN-máy-tính>:3000` |

Với điện thoại thật: lấy IP LAN của Mac bằng `ipconfig getifaddr en0`. iPhone cần bật **Chế độ nhà phát triển**, chọn Team ký app trong Xcode (`ios/Runner.xcworkspace`), và cho phép quyền **Mạng cục bộ** khi app hỏi.

### 6. Điện thoại khác Wi-Fi + nhận webhook SePay (ngrok)

ngrok mở cổng `:3000` của máy ra internet. Điện thoại ở bất kỳ mạng nào cũng gọi được API, và SePay gọi được webhook báo tiền về.

```bash
brew install ngrok
ngrok config add-authtoken <token ở dashboard.ngrok.com>     # lần đầu
ngrok http 3000                                               # hoặc --url=<domain-tĩnh>.ngrok-free.app để địa chỉ không đổi
```

1. Chạy app với địa chỉ ngrok: `flutter run --dart-define=API_BASE=https://<id>.ngrok-free.app`
2. SePay → **Tích hợp WebHooks**: URL `https://<id>.ngrok-free.app/payments/sepay-webhook`, chứng thực **API Key** = `SEPAY_API_KEY` trong `backend/.env`. Tài khoản nhận tiền phải được liên kết với SePay.
3. Chuyển **đúng số tiền**, giữ nguyên nội dung `DACN<số lịch>`. Tiền về → lịch tự chuyển "đã thanh toán", app hiện màn thành công trong khoảng 3 giây.

Webhook chỉ tới được khi máy đang chạy cả backend lẫn ngrok. Địa chỉ ngrok ngẫu nhiên đổi mỗi lần chạy lại ngrok (dùng domain tĩnh để tránh phải sửa lại SePay). Flutter web nên dùng `localhost`.

### Tài khoản

- **Admin** (có sẵn): `admin@dacn.local` / `Admin@123`
- **Bác sĩ:** admin tạo trong app (bắt buộc ảnh đại diện).
- **Bệnh nhân:** tự đăng ký. Các CCCD mẫu có trong danh bạ BHYT:

  | CCCD | Ngày sinh | Thẻ |
  |---|---|---|
  | `079203000111` | 2002-06-15 | 80% |
  | `079096000222` | 1996-03-10 | 95% |
  | `048085000333` | 1985-11-20 | 100% |
  | `001090000444` | 1990-01-05 | hết hạn |

Xoá sạch dữ liệu để demo lại (giữ admin, mẫu ca trực, danh bạ BHYT): `cd backend && npx ts-node src/reset-db.ts`.

## Kiểm thử

```bash
cd backend && npm test            # unit test
npm run test:e2e                  # e2e trên DB dev
node test/api-smoke.mjs           # smoke toàn bộ API (cần API + AI đang chạy)
cd ../frontend && flutter analyze && flutter test
```

## Lỗi hay gặp

| Triệu chứng | Cách xử lý |
|---|---|
| API không kết nối được DB | `docker start my-postgres`, kiểm tra `DB_*` trong `backend/.env` |
| `relation ... does not exist` / thiếu cột | `npm run typeorm migration:run` |
| Điện thoại không gọi được API | Cùng Wi-Fi? Mở thử `http://<IP>:3000/api` trên trình duyệt điện thoại; khác Wi-Fi thì dùng ngrok (mục 6) |
| Đã chuyển khoản QR nhưng app không chuyển màn | Webhook SePay không tới backend: kiểm tra ngrok đang chạy và URL webhook trong SePay đúng (mục 6). Tạm thời admin bấm "Đã nhận tiền" |
| Web hiện bản cũ | Tải lại bằng Cmd+Shift+R (Flutter web có cache) |
| AI báo `Lỗi gọi Gemini: 503` | Gemini quá tải, thử lại sau; kiểm tra `GEMINI_API_KEY` |

## Nhóm

- Thái Văn Quý: Frontend
- Dương Quân: Backend
