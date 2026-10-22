# Plan 04: CCCD → BHYT, dịch vụ BHYT, thanh toán tiền mặt / VietQR + webhook SePay

Spec: `spec/04-cccd-bhyt-payment.md` (đã chốt Q1–Q6, mục 9 ghi đè các mục trên nếu mâu thuẫn). Nối tiếp phase 0–4 (`plans/00`–`03`).

## Quyết định khi lập plan

| # | Quyết định | Lý do |
| --- | --- | --- |
| P1 | `patient.cccd` dùng `select: false` → không bao giờ lộ qua relation (bác sĩ xem lịch, admin…). Chỉ `/patient/me` lấy riêng bằng `addSelect` | An toàn hơn "che một phần": mặc định không trả |
| P2 | Danh bạ BHYT = bảng `bhyt_registry`, **seed trong migration** (vài người mẫu). Không API/màn quản lý (Q3). `reset-db.ts` **không** xoá bảng này (dữ liệu tham chiếu, như BHXH) | Q3 |
| P3 | Bỏ hẳn khai thẻ của spec 03: xoá 3 cột thẻ trên `patient`, `PATCH /patient/me/insurance`, `InsuranceDTO`, các widget `InsuranceFields`/`InsuranceDraft` | Xoá thay vì để code chết |
| P4 | Module mới `payment/` gom: thanh toán của bệnh nhân, webhook SePay, danh sách/xác nhận thanh toán và thông báo của admin | Một chỗ cho mọi trạng thái `paymentStatus` |
| P5 | Bảng `payment_transaction` (`sepayId` UNIQUE) lưu mọi webhook nhận được → chống trùng khi SePay thử lại + đối soát | SePay retry tới 7 lần |
| P6 | Bảng `notification` (dùng chung cho mọi admin): `title`, `body`, `appointmentId?`, `readAt?`, `createdAt`. App admin hỏi số chưa đọc mỗi 15 giây | Không cần push/WebSocket cho đồ án |
| P7 | Bệnh nhân ở màn thanh toán hỏi trạng thái mỗi 3 giây (polling) | Đơn giản, không cần socket |
| P8 | Lottie: tự viết file `assets/lottie/success_check.json` (vòng tròn + dấu tích vẽ dần). Pháo giấy: `ConfettiWidget` hạt dạng dải dài (băng rôn) bắn từ trên xuống | Không tải file từ nguồn ngoài |
| P9 | Smoke test chèn bản ghi danh bạ riêng cho mỗi lần chạy qua `pg` (đã có trong backend) và xoá sau khi chạy, vì không có API danh bạ và CCCD là duy nhất | Q3 + chạy lặp lại được |
| P10 | Webhook trả `{success:true}` cho mọi giao dịch hợp lệ về chữ ký (kể cả không khớp lịch) để SePay không gửi lại; sai/thiếu API key → 401; chưa cấu hình `SEPAY_API_KEY` → 503 | Theo tài liệu SePay |

## Phase 5: Backend dữ liệu + CCCD + BHYT theo CCCD + tính tiền mới

### B5.1 Migration `CccdBhytPayment`
- `patient`: + `cccd` varchar(12) UNIQUE NULL; − `insuranceNumber`, `insuranceValidFrom`, `insuranceValidTo`.
- `bhyt_registry` (mới): `id`, `cccd` varchar(12) UNIQUE, `cardNumber` varchar(15) UNIQUE, `fullName`, `birthDate` date, `validFrom` date, `validTo` date. **Seed** 5 người mẫu (80% còn hạn, 95%, 100%, hết hạn, một người để demo).
- `disease`: + `bhytCovered` boolean NOT NULL DEFAULT true.
- `appointment_item`: + `bhytCovered` boolean NOT NULL DEFAULT true.
- `appointment`: + `examFeeCovered` boolean NULL, `insuranceCardNumber` varchar(15) NULL, `paymentMethod` varchar NULL, `paymentStatus` varchar NOT NULL DEFAULT 'unpaid', `paidAt` timestamp NULL, `paidBy` int NULL.
- `payment_transaction` (mới): `id`, `sepayId` bigint UNIQUE, `appointmentId` int NULL FK (SET NULL), `amount` int, `content` text, `matched` boolean, `createdAt`.
- `notification` (mới): `id`, `title`, `body` text, `appointmentId` int NULL, `readAt` timestamp NULL, `createdAt`.
- Entities + `data-source.ts`. `reset-db.ts`: thêm `payment_transaction`, `notification` (không thêm `bhyt_registry`). Chạy migration.

### B5.2 Billing util (test trước)
- `calcBill(examFee, examFeeCovered, items: {price, bhytCovered}[], card, apDate)` → `{examFee, examFeeCovered, total, coveredBase, insuranceRate, insuranceCovered, payable}` theo công thức spec 04 (chỉ phần có BHYT).
- Cập nhật `billing.util.spec.ts`: case cũ + dòng không BHYT, phí khám không BHYT, `coveredBase = 0`, ví dụ spec (150k+50k BHYT, 80k không → BHYT 160k, trả 120k).

### B5.3 BHYT theo CCCD
- `billing/bhyt-registry.entity.ts` + `billing/bhyt.service.ts` (`BillingModule` export): `findCard(cccd, birthDate)` → thẻ nếu có **và** ngày sinh trùng (so theo ngày VN), ngược lại `null`.
- Xoá `billing/insurance.dto.ts`, `PATCH /patient/me/insurance`, `updateInsurance`.

### B5.4 Đăng ký + hồ sơ
- `RegisterDTO`: bỏ `extends InsuranceDTO`; + `cccd` (`@Matches(/^\d{12}$/)`, trim). Service: trùng CCCD → 409 `CCCD đã được đăng ký`.
- `PatientEntity.cccd` `select: false`.
- `getProfile`: `addSelect cccd`; trả `cccd` + `insurance: null | {cardNumber, validFrom, validTo, rate, status}` (status theo hôm nay).

### B5.5 Bảng giá + hoàn thành khám
- `disease.dto`: + `bhytCovered?: boolean`. `DiseaseService`: + `examFeeBhytCovered` (env `EXAM_FEE_BHYT_COVERED`, mặc định true); `list()` trả thêm field này.
- `completeAppointment`: thẻ = `bhyt.findCard(patient.cccd, patient.birthDate)` (load `cccd` riêng vì `select:false`); `calcBill` mới; snapshot `examFeeCovered`, `insuranceCardNumber`, `bhytCovered` từng dòng; `payable = 0` → `paymentStatus = 'paid'`, `paidAt = now`.

### Kiểm tra Phase 5
- [ ] `npx jest src/billing` pass.
- [ ] Smoke (viết lại phần BHYT của phase 3): đăng ký thiếu/sai CCCD → 400; trùng CCCD → 409; CCCD có trong danh bạ + đúng ngày sinh → `/patient/me.insurance` có; lệch ngày sinh / không có → `null`; bác sĩ xem lịch không thấy `cccd`; ví dụ hoá đơn spec (280k, BHYT 160k, trả 120k); thẻ 100% + toàn BHYT → `payable 0` + `paid`; thẻ hết hạn → BHYT 0; đổi `bhytCovered` sau khi khám → hoá đơn cũ giữ nguyên.
- [ ] e2e: đăng ký thêm `cccd` ngẫu nhiên.
- [ ] tsc, jest, e2e, lint (không lỗi ngoài prettier ở file mới).

## Phase 6: Backend thanh toán + VietQR + webhook SePay + thông báo

### B6.1 VietQR (test trước)
- `billing/vietqr.util.ts`: `crc16(s)`, `buildVietQr({bin, accountNo, amount, content})` theo bảng trường trong spec. `vietqr.util.spec.ts`: CRC `"123456789"` = `29B1`; đúng thứ tự/độ dài trường; số tiền ≤ 0 hoặc nội dung không hợp lệ → throw.

### B6.2 Module `payment/`
- `POST /patient/appointment/:id/pay` (patient, `{method:'cash'|'qr'}`): kiểm tra chủ lịch (403), đã khám + có hoá đơn + chưa `paid` + `payable > 0` (400). Ghi `paymentMethod`, `paymentStatus='pending'`. QR: thiếu env ngân hàng → 503; trả `qr = {payload, bankName, accountNo, accountName, amount, content}`.
- `POST /payments/sepay-webhook` (`@Public`): kiểm tra `Authorization: Apikey …` (so sánh an toàn thời gian); bỏ qua `transferType !== 'in'`; trùng `sepayId` → trả success luôn; tìm `DACN(\d+)` trong `content`; khớp lịch chưa `paid` + `amount === payable` → `paid` (`paymentMethod='qr'`, `paidAt`) + thông báo "Đã nhận tiền"; lệch / không thấy lịch → thông báo cảnh báo. Lưu `payment_transaction`. Trả `{success:true}`.
- Admin (`@Roles('admin')`): `GET /admin/payments?status=pending|paid`, `POST /admin/payments/:id/confirm` (pending → paid, `paidBy`; đã paid → 400), `GET /admin/notifications`, `GET /admin/notifications/unread-count`, `POST /admin/notifications/read-all`.
- Env: `PAYMENT_BANK_BIN`, `PAYMENT_BANK_NAME`, `PAYMENT_ACCOUNT_NO`, `PAYMENT_ACCOUNT_NAME`, `SEPAY_API_KEY`, `EXAM_FEE_BHYT_COVERED`. Thêm giá trị dev vào `backend/.env` (tài khoản demo, bạn tự thay bằng tài khoản thật).

### Kiểm tra Phase 6
- [ ] `npx jest src/billing` (vietqr) pass.
- [ ] Smoke: thanh toán lịch chưa khám / của người khác / đã paid → 400/403/400; tiền mặt → pending; đổi QR → `qr.payload` đúng BIN/STK/số tiền/`DACN{id}` + CRC hợp lệ; webhook sai key → 401; webhook đúng (số tiền khớp) → `paid` + 1 thông báo có tên BN, tên BS, số tiền; gửi lại cùng `id` → không tạo thêm thông báo; số tiền lệch → vẫn pending + thông báo cảnh báo; admin xác nhận tiền mặt → paid, xác nhận lại → 400; bệnh nhân gọi API admin → 403; unread-count/read-all đúng.
- [ ] tsc, jest, e2e, lint.

## Phase 7: Flutter

- **F7.1 Model/service**: `Appointment` + `paymentStatus`, `paymentMethod`, `paidAt`, `examFeeCovered`, `insuranceCardNumber`; `BillItem.bhytCovered`; `Patient` + `cccd`, `insurance` (object hoặc null), bỏ field thẻ cũ; `Disease.bhytCovered`, `PriceList.examFeeBhytCovered`. `services/payment_service.dart` (pay, admin payments/confirm, notifications).
- **F7.2 Đăng ký**: + ô CCCD bắt buộc (12 số, `FilteringTextInputFormatter.digitsOnly`, `maxLength 12`); bỏ mục BHYT. `AuthService/AuthProvider.register` thay `insurance` bằng `cccd`.
- **F7.3 Hồ sơ**: CCCD chỉ đọc; card "Mã BHYT" chỉ hiện khi `insurance != null`; bỏ form thẻ. Xoá `InsuranceFields`, `InsuranceDraft`, `cardRegex`… không còn dùng.
- **F7.4 Hoá đơn**: `BillCard` có nhãn BHYT từng dòng, dòng "BHYT chi trả (80% × coveredBase)", "Cần thanh toán", chip trạng thái thanh toán. Chi tiết lịch bệnh nhân: nút "Thanh toán" / "Đổi phương thức" → `PaymentScreen`.
- **F7.5 `PaymentScreen`**: `BillCard` + 2 `RadioListTile` + nút xác nhận; tiền mặt → hướng dẫn tại quầy; QR → `QrImageView(data: payload, version: QrVersions.auto, size: 240)` + thông tin ngân hàng + nút copy nội dung. Polling 3 giây khi `pending`; `paid` → `PaymentSuccess` overlay: `Lottie.asset('assets/lottie/success_check.json', repeat: false)` + 2–3 `ConfettiWidget` (dải dài như băng rôn, rơi từ trên xuống). Dependencies mới: `qr_flutter`, `lottie`, `confetti`.
- **F7.6 Admin**: AppBar gọn lại = chuông thông báo (badge số chưa đọc, polling 15 giây) + menu (Tin tức, Bảng giá, Thanh toán, Đăng xuất). `AdminNotificationsScreen` (mở là đánh dấu đã đọc). `AdminPaymentsScreen` (tab Chờ xác nhận / Đã thanh toán, nút "Đã nhận tiền"). Bảng giá: chip/công tắc "BHYT" mỗi dòng, dòng phí khám hiện trạng thái BHYT.
- **F7.7 Bác sĩ**: dialog chọn bệnh hiện nhãn BHYT.

### Kiểm tra Phase 7
- [ ] `flutter analyze` không thêm issue, `flutter test` pass, `flutter build web` OK.
- [ ] Chụp màn hình (`screenshots/phase-4/`… đặt tên theo phase 5–7): đăng ký có CCCD; hồ sơ có / không có ô Mã BHYT; hoá đơn có nhãn BHYT; màn thanh toán tiền mặt; màn QR; animation thành công (sau khi giả lập webhook); admin chuông + danh sách thông báo; admin thanh toán chờ xác nhận; bảng giá có cờ BHYT.

## Phase 8: Tài liệu
- Wiki: `api-routes`, `database-schema`, `auth-flow` (CCCD), `patient-module`, `doctor-module`, `admin-module`, `ui-components`, `critical-constraints` (CCCD `select:false`, webhook key), `log`, `INDEX`.
- `CLAUDE.md`: env mới, module `payment/`, cách test webhook (smoke + ngrok/SePay).
- `spec/README.md`: đánh dấu spec 04 đã triển khai.
