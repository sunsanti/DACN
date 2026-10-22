# TODO

Nguồn: `plans/` (chi tiết từng bước xem file plan tương ứng, mã bước như `B0.1` khớp với plan).
Thứ tự: Phase 0 → (Phase 1, Phase 2 song song được) → Phase 3 → Phase 4.

## Trước khi bắt đầu
- [ ] Duyệt D2 (không xoá bệnh, chỉ tắt) và D3 (bắt buộc chọn bệnh khi hoàn thành) trong `plans/README.md`
- [x] Thêm `EXAM_FEE=150000` vào `backend/.env`

---

## Phase 0: Nền upload ảnh ([plan](plans/00-foundation.md))

### Backend
- [x] B0.1 Tạo `backend/src/common/upload.ts`: `imageUpload(subdir)` (diskStorage, tên UUID, chỉ jpeg/png/webp, ≤ 2 MB), `toPublicPath`, `removeUpload`
- [x] B0.2 `main.ts`: `NestExpressApplication` + `useStaticAssets` cho `/uploads`
- [x] B0.3 `.gitignore`: thêm `backend/uploads/`

### Frontend
- [x] F0.1 `core/ui.dart`: helper `imageUrl(path)` + widget `UserAvatar` (ảnh hoặc chữ cái đầu)

### Kiểm tra
- [x] `curl -I /uploads/avatars/x.png` trả 200, không cần token
- [x] Không đọc được file ngoài `uploads/` bằng `../`
- [x] `npm run lint`, `npm test`, `flutter analyze` sạch
- [ ] Commit phase 0

---

## Phase 1: Ảnh đại diện ([plan](plans/01-avatar.md))

### Backend
- [x] B1.1 Migration `AddDoctorAvatar` + cột `avatar` trên `DoctorEntity`
- [x] B1.1 Chạy `npm run typeorm migration:run`
- [x] B1.2 `@Type(() => Number)` cho `age` trong `RegisterDTO` và `RegisterDoctorDTO`
- [x] B1.3 `auth.controller`: register (avatar tuỳ chọn) và register-doctor (avatar bắt buộc) nhận multipart. Lỗi thì xoá file vừa upload
- [x] B1.4 `auth.service`: lưu đường dẫn avatar. `sign()` trả thêm `name`, `avatarUrl`
- [x] B1.5 Các endpoint doctor list/detail, `/patient/me`, chi tiết appointment trả `avatar`
- [x] B1.6 Grep `backend/test/` rồi xoá `POST /doctor/create-doctor`

### Frontend
- [x] F1.1 `AuthResult`, `token_store`, `AuthProvider` thêm `name`, `avatarUrl`. Model doctor/patient thêm `avatar`
- [x] F1.2 `auth_service.register` + `admin_service` tạo bác sĩ chuyển sang `FormData` (`MultipartFile.fromBytes`)
- [x] F1.3 `register_screen`: chọn ảnh (tuỳ chọn) + preview
- [x] F1.3 `add_doctor_screen`: chọn ảnh (bắt buộc), nút "Tạo" disabled khi chưa có ảnh
- [x] F1.3 Header 3 home screen: `UserAvatar` + "Xin chào, {name}"
- [x] F1.3 `create_appointment_screen`: ảnh bác sĩ trong danh sách + ảnh to cho bác sĩ đang chọn
- [x] F1.3 Ảnh trong các màn chi tiết lịch hẹn (2 phía) + `admin_doctor_detail_screen`

### Kiểm tra
- [x] Smoke: register không ảnh trả 201, có ảnh thì có `avatarUrl` và GET được ảnh
- [x] Smoke: register-doctor không ảnh trả 400
- [x] Smoke: email trùng kèm ảnh thì không để lại file rác
- [x] Sửa `test/patient-flow.e2e-spec.ts` nếu cần, `npm run test:e2e` pass
- [x] Tay: login thấy avatar, kill app mở lại vẫn thấy. Bác sĩ cũ hiện chữ cái đầu
- [x] `npm run lint`, `npm test`, `flutter analyze` sạch
- [ ] Commit phase 1 (backend, frontend)

---

## Phase 2: Tin tức + carousel ([plan](plans/02-news.md))

### Backend
- [x] B2.1 `src/news/`: entity, DTO (`title`, `url` http/https), service, controller
- [x] B2.1 `GET /news?limit` (đã login, tối đa 50), `POST /news` (admin, multipart, thiếu ảnh trả 400), `DELETE /news/:id` (admin, xoá cả file)
- [x] B2.2 Đăng ký `NewsModule` trong `app.module.ts`, thêm `NewsEntity` vào `data-source.ts`
- [x] B2.2 Migration `CreateNews` + chạy `npm run typeorm migration:run`
- [x] B2.2 `reset-db.ts`: thêm `news` vào TRUNCATE

### Frontend
- [x] F2.1 `models/news.dart`, `services/news_service.dart`, state news trong `AdminProvider`
- [x] F2.2 Thêm `url_launcher` + cấu hình `Info.plist` / `AndroidManifest.xml` + helper `openExternal`
- [x] F2.3 `NewsCarousel` (PageView, tự chuyển 5s, chấm chỉ trang, ảnh lỗi hiện placeholder) ở `patient_home_screen`
- [x] F2.3 Danh sách "Tin tức" bên dưới carousel. Không có tin thì ẩn cả hai
- [x] F2.4 Admin: mục "Tin tức" (danh sách, xoá có xác nhận, form thêm có preview ảnh)

### Kiểm tra
- [x] Smoke: admin tạo tin trả 201, patient và doctor tạo trả 403
- [x] Smoke: `javascript:` URL trả 400, thiếu ảnh trả 400, file `.pdf` hoặc ảnh > 2 MB trả 400 và không có file rác
- [x] Smoke: DELETE xoá cả file ảnh. `limit=5` trả ≤ 5 tin, mới nhất ở đầu
- [x] Tay: tin mới hiện đầu carousel, bấm vào mở trình duyệt ngoài. Ảnh lỗi hiện placeholder
- [x] `npm run lint`, `npm test`, `flutter analyze` sạch
- [ ] Commit phase 2 (backend, frontend)

---

## Phase 3: BHYT + bảng giá bệnh + hoá đơn ([plan](plans/03-insurance-pricing.md))

### Backend
- [x] B3.1 `src/billing/billing.util.ts`: `CARD_REGEX`, `rateFromCard`, `cardStatus`, `calcBill(examFee, itemPrices[], card, apDate)`
- [x] B3.1 `billing.util.spec.ts`: không thẻ, hết hạn, chưa hiệu lực, đúng ngày `validTo`, mức 1/3/4, làm tròn, nhiều bệnh, giá 0
- [x] B3.2 Migration `AddInsuranceAndPricing`: cột thẻ trên `patient`, bảng `disease`, cột tổng trên `appointment`, bảng `appointment_item`
- [x] B3.2 Entity `DiseaseEntity`, `AppointmentItemEntity` + quan hệ `items`. Thêm vào `data-source.ts`
- [x] B3.2 Chạy `npm run typeorm migration:run`
- [x] B3.2 `reset-db.ts`: thêm `disease` vào TRUNCATE
- [x] B3.3 `src/disease/`: `GET /diseases` (admin thấy tất cả, doctor chỉ thấy bệnh active; trả `{ examFee, items }`), `POST`/`PATCH` (admin), tên trùng trả 409
- [x] B3.3 Import `DiseaseModule` vào `app.module.ts`, export `TypeOrmModule` cho `DoctorModule`
- [x] B3.4 `InsuranceDTO` + field thẻ tuỳ chọn trong `RegisterDTO`
- [x] B3.4 `PATCH /patient/me/insurance`. `/patient/me` trả thêm `insuranceRate`, `insuranceStatus`
- [x] B3.5 `CompleteDTO` (`diseaseIds[]`, ≥ 1, không trùng)
- [x] B3.5 `completeAppointment`: `assertOwns` → chỉ lịch đã xác nhận (`confirmCondition=0`) và chưa huỷ → kiểm tra bệnh active → `calcBill` → ghi trong transaction
- [x] B3.5 Truy vấn chi tiết appointment load thêm `items`
- [x] B3.6 Ghi `EXAM_FEE` vào phần env của `CLAUDE.md`

### Frontend
- [x] F3.1 Model `appointment` (tổng tiền + `items`), `patient` (thẻ), `disease`. Hàm `formatVnd`
- [x] F3.2 `register_screen`: mục BHYT tuỳ chọn, hiện mức hưởng
- [x] F3.2 `profile_screen`: xem/sửa/xoá thẻ + badge trạng thái
- [x] F3.2 Widget `BillCard` + hiện ở `appointment_detail_screen` khi đã khám
- [x] F3.3 Dialog chọn nhiều bệnh (checkbox, tìm kiếm, tạm tính) khi bác sĩ bấm "Hoàn thành"
- [x] F3.3 `doctor_service.complete(id, diseaseIds)` + `DoctorProvider`. Hiện `BillCard` sau khi hoàn thành
- [x] F3.4 Admin: màn "Bảng giá bệnh" (danh sách, thêm, sửa, bật/tắt)

### Kiểm tra
- [x] `npx jest src/billing` pass
- [x] Smoke: 2 bệnh (50k + 100k), thẻ 80% → `total=300000`, `covered=240000`, `payable=60000`, 2 dòng `items`
- [x] Smoke: 1 bệnh 50k → `covered=160000`, `payable=40000`
- [x] Smoke: thẻ hết hạn trước ngày khám → `covered=0`
- [x] Smoke: `diseaseIds` rỗng/trùng/không tồn tại/đã tắt trả 400, không ghi `items`. Bác sĩ khác trả 403/404
- [x] Smoke: đổi giá bệnh sau khi hoàn thành → hoá đơn cũ không đổi
- [x] Smoke: mã thẻ `AB6…` trả 400, `validTo < validFrom` trả 400. Patient `POST /diseases` trả 403
- [x] Smoke: complete lịch đang chờ hoặc đã huỷ trả 400
- [x] Smoke: bệnh đã tắt không hiện với doctor, admin vẫn thấy
- [x] Tay: luồng đầy đủ admin → bệnh nhân → bác sĩ → bệnh nhân thấy hoá đơn
- [x] `npm run lint`, `npm test`, `npm run test:e2e`, `flutter analyze` sạch
- [ ] Commit phase 3 (backend, frontend)

---

## Phase 4: Tài liệu
- [x] Sửa `spec/03-insurance.md` theo luồng mới (phí cố định + nhiều bệnh, tính lúc hoàn thành)
- [x] `spec/README.md`: đánh dấu Q1–Q3 đã chốt, đổi trạng thái
- [x] `spec/01-news.md`: ghi rõ chỉ ở bệnh nhân. `spec/02-avatar.md`: ghi rõ route `/auth/register-doctor`, key `avatarUrl` (login) và `avatar` (entity)
- [x] `wiki/api-routes.md`, `wiki/database-schema.md`, `wiki/auth-flow.md` (ghi rõ `avatarUrl` ở login, `avatar` ở entity)
- [x] `wiki/doctor-module.md`, `wiki/patient-module.md`, `wiki/admin-module.md`, `wiki/ui-components.md`
- [x] `CLAUDE.md`: env `EXAM_FEE`, thư mục `backend/uploads/`
- [x] `wiki/log.md`: mỗi phase một dòng
- [x] ~~Dump lại `backend/schema.sql`~~ → không ghi đè (file có dữ liệu + thay đổi chưa commit của bạn). Đã kiểm chứng: `schema.sql` + `npm run typeorm migration:run` dựng đủ 11 bảng; ghi hướng dẫn vào `CLAUDE.md`

---

# Đợt 2: CCCD → BHYT + thanh toán ([plan](plans/04-cccd-bhyt-payment.md), [spec](spec/04-cccd-bhyt-payment.md))

## Phase 5: Backend CCCD + BHYT theo CCCD + tính tiền mới
- [x] B5.1 Migration `CccdBhytPayment` (patient.cccd, bỏ cột thẻ cũ, `bhyt_registry` + seed, `bhytCovered`, cột thanh toán, `payment_transaction`, `notification`) + entities + `data-source.ts` + `reset-db.ts`
- [x] B5.1 Chạy `npm run typeorm migration:run`
- [x] B5.2 `calcBill` mới (chỉ phần có BHYT) + test
- [x] B5.3 `BhytService.findCard(cccd, birthDate)` + xoá khai thẻ cũ (`InsuranceDTO`, `PATCH /patient/me/insurance`)
- [x] B5.4 Đăng ký bắt buộc CCCD (12 số, trùng → 409), `cccd` `select:false`, `/patient/me` trả `cccd` + `insurance`
- [x] B5.5 `bhytCovered` cho bảng giá + `examFeeBhytCovered`; hoàn thành khám dùng công thức mới, snapshot, `payable 0` → paid
- [x] Kiểm tra: jest billing, smoke phần CCCD/BHYT/hoá đơn, e2e (thêm cccd), tsc, lint
- [x] Chụp màn hình phase 5 → `screenshots/phase-5/smoke-result.txt` (92/92; phase này chỉ có API)

## Phase 6: Backend thanh toán + VietQR + webhook SePay + thông báo
- [x] B6.1 `vietqr.util.ts` (`crc16`, `buildVietQr`) + test
- [x] B6.2 `POST /patient/appointment/:id/pay` (cash/qr, payload VietQR, 503 nếu chưa cấu hình)
- [x] B6.2 `POST /payments/sepay-webhook` (API key, chống trùng `sepayId`, khớp `DACN{id}` + số tiền → paid + thông báo; lệch → cảnh báo)
- [x] B6.2 Admin: `GET /admin/payments`, `POST /admin/payments/:id/confirm`, `GET /admin/notifications`, `unread-count`, `read-all`
- [x] B6.2 Env thanh toán + SePay vào `backend/.env` (giá trị demo)
- [x] Kiểm tra: jest 14/14, smoke 106/106 (`screenshots/phase-6/smoke-result.txt`), e2e 9/9, tsc, lint

## Phase 7: Flutter
- [x] F7.1 Model + `payment_service.dart`
- [x] F7.2 Đăng ký: ô CCCD bắt buộc, bỏ mục BHYT
- [x] F7.3 Hồ sơ: CCCD chỉ đọc, ô "Mã BHYT" chỉ hiện khi có; xoá widget khai thẻ cũ
- [x] F7.4 `BillCard` nhãn BHYT + "Cần thanh toán" + trạng thái; nút Thanh toán
- [x] F7.5 `PaymentScreen` (tiền mặt / QR `qr_flutter`, polling 3s) + `PaymentSuccess` (Lottie dấu tích + confetti băng rôn)
- [x] F7.6 Admin: chuông thông báo + menu, `AdminNotificationsScreen`, `AdminPaymentsScreen`, cờ BHYT trong bảng giá
- [x] F7.7 Dialog bác sĩ hiện nhãn BHYT
- [x] Kiểm tra: analyze, test, build web
- [x] Chụp màn hình phase 7 → `screenshots/phase-7/` (12 ảnh + smoke 106/106). Ảnh QR không cuộn được tới phần thông tin ngân hàng (giới hạn công cụ chụp), phần đó đã được smoke kiểm tra

## Phase 8: Tài liệu
- [x] Wiki (api-routes, database-schema, auth-flow, patient/doctor/admin module, ui-components, critical-constraints, log, INDEX)
- [x] `CLAUDE.md` (env mới, module payment, cách test webhook)
- [x] `spec/README.md` đánh dấu spec 04 đã triển khai
- [ ] Commit (chờ bạn quyết cách commit, như đợt 1)

---

# Đợt 3: làm mới giao diện ([spec](spec/05-ui-revamp.md) · [plan](plans/05-ui-revamp.md))

Thứ tự: (Phase 9 ∥ Phase 10) → **cổng duyệt `pre_implement/`** → (Phase 11 ∥ Phase 12) → Phase 13 → Phase 14.

## Trước khi bắt đầu
- [ ] Duyệt spec 05 và trả lời Q1–Q6 (mục 11 của spec)
- [x] Q3: dùng `@nestjs/throttler` (chỉ áp cho bhyt-lookup)

## Phase 9: Template + mockup (`ui-preview`)
- [x] U9.1 Tìm 2–3 template, ghi link + giấy phép vào `pre_implement/README.md`
- [x] U9.2 Chốt hướng chung: màu, bo góc, kiểu bubble/thẻ
- [x] U9.3 4 mockup PNG: patient-home, patient-register, admin-home, doctor-home
- [ ] U9.4 **Bạn duyệt** → ghi "Đã duyệt" vào README

## Phase 10: Tra BHYT khi đăng ký (`register-bhyt`)
- [x] B10.1 `BhytLookupDto`
- [x] B10.2 `maskCardNumber` + unit test
- [x] B10.3 `POST /auth/bhyt-lookup` (`@Public`)
- [x] B10.4 Giới hạn 10 request/phút/IP (429)
- [x] B10.5 Test: có thẻ / sai ngày sinh / CCCD 11 số / mã đã che (unit). Smoke: kiểm tra bằng curl (có thẻ, hết hạn, sai ngày sinh, 400, 429)
- [x] F10.1 `AuthService.bhytLookup`
- [x] F10.2 Ô "Thẻ BHYT" xám, tự tra khi đủ CCCD + ngày sinh (cờ `_birthPicked`)
- [x] Kiểm tra: test, analyze, chụp 2 ca → `screenshots/phase-10/`

## Phase 11: Trang chủ bệnh nhân (`patient-home`), sau cổng duyệt
- [x] F11.1 Widget `Bubble` trong `core/ui.dart`
- [x] F11.2 `MyAppointmentsScreen` + chip lọc
- [x] F11.3 `PaidBillsScreen`
- [x] F11.4 Home: carousel + 6 bubble có badge, bỏ FAB
- [x] F11.5 Bubble "Báo cáo AI": chọn lịch hẹn
- [x] F11.6 Carousel: mũi tên trái/phải + widget test
- [x] Kiểm tra: analyze, test (4/4), chụp → `screenshots/phase-11/` (tài khoản test chưa có lịch hẹn nên ảnh không có badge)

## Phase 12: Điều hướng admin (`admin-nav`), sau cổng duyệt
- [x] F12.1 Bỏ AppBar riêng của 3 màn con (chỉ dùng làm tab nên không cần `embedded`)
- [x] F12.2 `NavigationBar` + `IndexedStack` (bỏ Rail: app bị giới hạn 560 px)
- [x] F12.3 AppBar: tiêu đề theo tab, chuông, Đăng xuất riêng
- [x] F12.4 Badge chưa đọc trên chuông + mục Thanh toán (`99+`)
- [x] Kiểm tra: analyze, test; badge kiểm bằng 3 thông báo tạm trong DB (đã xoá); chụp → `screenshots/phase-12/`

## Phase 13: Giao diện bác sĩ (`doctor-ui`), sau cổng duyệt
- [ ] F13.1 Đầu trang + 3 thẻ thống kê
- [ ] F13.2 Nút / mục "Ca làm"
- [ ] F13.3 Thẻ lịch hẹn gọn, hành động phụ trong bottom sheet
- [ ] Checklist hồi quy 10 hành động (xem plan) + chụp → `screenshots/phase-13/`

## Phase 14: Tài liệu
- [ ] Wiki (api-routes, auth-flow, ui-components, patient/admin/doctor module, log)
- [ ] `spec/README.md` đánh dấu spec 05
- [ ] Commit theo từng phase
