---
last_updated: 2026-10-04
tags: [frontend, flutter, ui, provider]
---

# UI Components (Flutter Frontend)

**Status: ĐẦY ĐỦ 3 VAI.** `frontend/lib/` là app DACN thật, `AuthGate` điều hướng theo role.
State management **Provider**, HTTP **dio** + JWT interceptor (auto-logout 401), token trong
`shared_preferences`. Base URL: web/iOS `localhost:3000`, Android emulator `10.0.2.2:3000`.

- **Bệnh nhân:** login/register → home (list lịch) → hồ sơ (xem/sửa) → đặt lịch theo **slot rảnh**
  → chi tiết lịch (sửa/xoá) → gửi ảnh+triệu chứng AI → PDF.
- **Bác sĩ:** 3 tab (chờ/đã xác nhận/đã khám) → xác nhận / đổi lịch / đã-khám / tái khám / xoá /
  tải PDF; chi tiết lịch + thông tin bệnh nhân; **ca trực** (đăng ký theo ngày, hủy, xoá) +
  xem tất cả ca trực.
- **Admin:** danh sách bác sĩ + giờ làm/lương; thêm bác sĩ; xem/sửa thông tin bác sĩ.

## Bổ sung 2026-10-04 (avatar, tin tức, BHYT + hoá đơn)

| Thành phần | File | Ghi chú |
| --- | --- | --- |
| `UserAvatar`, `AvatarPicker`, `SessionTitle`, `imageUrl()`, `fmtMoney()` | `core/ui.dart` | Avatar ảnh hoặc chữ cái đầu; header "Xin chào, {name}" ở 3 home |
| `Bubble` | `core/ui.dart` | Nút tròn icon + nhãn + `Badge` đếm (99+), dùng ở trang chủ bệnh nhân (spec 05) |
| `NewsCarousel`, `NewsTile`, `NewsImage`, `openExternal()` | `core/news_ui.dart` | `PageView` tự chuyển 5s, mũi tên trái/phải (vòng lại 2 đầu, ẩn khi 1 tin; bấm/vuốt reset timer), ảnh lỗi → placeholder; web dùng `LaunchMode.platformDefault` (web không hỗ trợ `externalApplication`) |
| `BillCard`, `PaymentChip`, `BhytTag`, `pickDiseases()`, `InsuranceBadge` | `core/billing_ui.dart` | Hoá đơn có nhãn BHYT từng dòng, "BHYT chi trả (80% × coveredBase)", "Cần thanh toán" + trạng thái thanh toán; dialog chọn nhiều bệnh (nhãn BHYT) |
| `PaymentScreen` | `screens/payment_screen.dart` | Hoá đơn + chọn Tiền mặt / QR; QR vẽ bằng `QrImageView` (`qr_flutter`) từ `qr.payload`; polling 3 s |
| `PaymentSuccess` | `core/payment_success.dart` | `Lottie.asset('assets/lottie/success_check.json', repeat: false)` (file tự viết) + 3 `ConfettiWidget` hạt dài (băng rôn) rơi từ trên |
| `AdminPaymentsScreen`, `AdminNotificationsScreen` | `screens/` | Admin xác nhận tiền / hộp thông báo |
| `AdminNewsScreen`, `AdminDiseaseScreen` | `screens/` | Admin quản lý tin / bảng giá |
| Services | `news_service.dart`, `disease_service.dart` | `imagePart()` (trong `auth_service.dart`) tạo multipart từ bytes để chạy cả web |

- Patient home: carousel 5 tin mới → lịch khám → danh sách tin. Chỉ bệnh nhân thấy tin tức.
- Ảnh tải bằng `Image.network(ApiConfig.baseUrl + path)`; Flutter web (CanvasKit) cần header CORS trên `/uploads` (backend đã đặt static sau `enableCors`).
- Dep mới: `url_launcher` (iOS `LSApplicationQueriesSchemes`, Android `<queries>` VIEW https), `qr_flutter`, `lottie`, `confetti`. Asset: `assets/lottie/`.
- Đăng ký: ô CCCD bắt buộc (chỉ số, 12 ký tự). Hồ sơ: CCCD chỉ đọc + khối "Mã BHYT" chỉ hiện khi có thẻ.

## Cấu trúc `frontend/lib/`

| Path | Vai trò |
| --- | --- |
| `config/api_config.dart` | `baseUrl` (mặc định `http://10.0.2.2:3000` cho Android emulator; override bằng `--dart-define=API_BASE=...`) |
| `core/token_store.dart` | Lưu token/role/patientId qua `shared_preferences` |
| `core/dio_client.dart` | Dio + interceptor gắn `Bearer`, 401 → `onUnauthorized` (auto-logout) |
| `models/` | `auth_result`, `doctor`, `appointment` |
| `services/` | `auth_service`, `appointment_service`, `ai_service` (multipart `/ai/report`) |
| `providers/` | `auth_provider` (login/register/logout/restore), `appointment_provider` |
| `screens/` | `login`, `register`, `patient_home`, `create_appointment`, `ai_report` |
| `main.dart` | `MultiProvider` + `AuthGate` route theo role |

## Luồng bệnh nhân

Login/Register → `PatientHomeScreen` (carousel tin + 6 `Bubble`: Đặt lịch, Lịch hẹn, Chờ thanh toán, Hoá đơn đã trả, Báo cáo AI, Hồ sơ; badge đếm từ `GET /patient/list-appointment`) → `MyAppointmentsScreen` (danh sách + `FilterChip` theo `AppointmentFilter`) / `PaidBillsScreen` (lọc `isPaid` ở client) →
`CreateAppointmentScreen` (chọn bác sĩ `GET /doctor/list`, ngày/giờ, địa chỉ, ghi chú →
`POST /patient/create-appointment`) → `AiReportScreen` (chọn ảnh + triệu chứng →
`POST /ai/report` multipart → nhận bytes PDF → lưu temp → mở bằng `open_filex`).

## Deps (pubspec.yaml)

`provider`, `dio`, `shared_preferences`, `image_picker`, `path_provider`, `open_filex`, `url_launcher`.

## Chạy

```bash
cd frontend
flutter pub get
# Bật backend + AI: (thư mục backend) npm run start:dev
flutter run        # chọn emulator Android
# Thiết bị thật: flutter run --dart-define=API_BASE=http://<IP_LAN>:3000
```

## Ràng buộc đã xử lý

- **Cleartext HTTP:** `android/app/src/main/AndroidManifest.xml` thêm `usesCleartextTraffic="true"`
  + quyền `INTERNET` (kẻo `http://` bị Android chặn).
- **Base URL emulator:** `10.0.2.2` (không phải `localhost`).
- Không gọi AI service (8000) trực tiếp — luôn qua backend `/ai/*` (key Gemini ở server).

Related: [[api-routes]] · [[ai-integration]] · [[auth-flow]] · [[project-architecture]]
