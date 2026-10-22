# Plan 05: làm mới giao diện (Phase 9–14)

Ngày: 2026-10-22 · Nguồn: [`spec/05-ui-revamp.md`](../spec/05-ui-revamp.md) · Tiến độ: `TODO.md`

## Thứ tự và phụ thuộc

```
Phase 9  ui-preview ─────┐
                         ├─► CỔNG DUYỆT (bạn duyệt pre_implement/) ─► Phase 11 patient-home ─┐
Phase 10 register-bhyt ──┘          (Phase 10 không cần chờ cổng)    Phase 12 admin-nav ────┼─► Phase 13 doctor-ui ─► Phase 14 tài liệu
```

- Phase 9 và 10 chạy song song. Phase 10 chủ yếu là backend, giao diện chỉ là một ô trong form có sẵn, nên không phụ thuộc template.
- Phase 11 và 12 song song được vì không sửa chung file nào, chỉ cùng thêm widget vào `core/ui.dart`. Ai làm trước thì người sau rebase.
- Phase 13 làm cuối vì note yêu cầu xem trước, và nó dùng lại widget `Bubble` / thẻ thống kê từ Phase 11.

## Phase 9: `ui-preview` (cổng duyệt)

| Mã | Việc | File | Xong khi |
|---|---|---|---|
| U9.1 | Tìm 2–3 template app đặt lịch khám (Figma Community / Dribbble / UI kit Flutter mã nguồn mở). Ghi link, giấy phép, ưu/nhược | `pre_implement/README.md` | ≥ 2 link mở được, có cột giấy phép |
| U9.2 | Chốt một hướng chung: bảng màu (giữ `primary` hiện tại hay đổi), bo góc, kiểu bubble/thẻ | `pre_implement/README.md` | Có một mục "Đề xuất" |
| U9.3 | Vẽ 4 mockup theo app thật: `patient-home`, `patient-register`, `admin-home`, `doctor-home`. Cách vẽ: dựng HTML tĩnh rồi chụp PNG khổ 390×844 (không thêm dependency vào app) | `pre_implement/*.png`, `pre_implement/src/*.html` | 4 ảnh, chữ tiếng Việt, đúng chức năng hiện có |
| U9.4 | Gửi bạn duyệt, ghi quyết định vào README | `pre_implement/README.md` | Có mục "Đã duyệt" kèm ngày |

Rủi ro: template đẹp nhưng không hợp Material 3, làm lại tốn công. Cách giảm rủi ro: chỉ mượn **bố cục và màu**, mọi widget vẫn là Material có sẵn.

## Phase 10: `register-bhyt`

| Mã | Việc | File | Xong khi |
|---|---|---|---|
| B10.1 | DTO `BhytLookupDto` (`cccd` `^\d{12}$`, `birthDate` `IsDateString`) | `backend/src/auth/dto/bhyt-lookup.dto.ts` | Sai định dạng trả 400 |
| B10.2 | Hàm `maskCardNumber(code)`: giữ 3 đầu + 4 cuối. Viết unit test | `backend/src/billing/bhyt.service.ts` (+ `.spec.ts`) | Test pass |
| B10.3 | `POST /auth/bhyt-lookup` `@Public()`, gọi `findCard`, trả `{found, cardNumber, rate, validTo, valid}` | `auth.controller.ts`, `auth.service.ts` (hoặc gọi thẳng `BhytService`), `auth.module.ts` | curl trả đúng 2 ca có thẻ / không thẻ |
| B10.4 | Giới hạn 10 request/phút/IP (cần duyệt Q3: thêm `@nestjs/throttler`) | `app.module.ts`, `auth.controller.ts`, `package.json` | Request thứ 11 trong 1 phút trả 429 |
| B10.5 | Unit test controller/service: có thẻ, sai ngày sinh, CCCD 11 số, mã đã che. Thêm bước vào smoke test | `auth/*.spec.ts`, `test/api-smoke.mjs` | `npm test` + smoke pass |
| F10.1 | `AuthService.bhytLookup(cccd, birthDate)` | `frontend/lib/services/auth_service.dart` | — |
| F10.2 | Ô "Thẻ BHYT" xám, không sửa được, đặt dưới Ngày sinh. Tự tra (chờ 400 ms) khi đủ 12 số CCCD và đã chọn ngày sinh. Đủ 6 trạng thái như spec 3.2 | `frontend/lib/screens/register_screen.dart` | Chụp ảnh 3 ca: có thẻ / không thẻ / hết hạn |

Rủi ro: `_birthDate` mặc định là `2000-01-01`, nên không biết người dùng đã chọn ngày hay chưa. Cách xử lý: thêm cờ `_birthPicked`, chỉ tra khi cờ bật.

## Phase 11: `patient-home`

| Mã | Việc | File | Xong khi |
|---|---|---|---|
| F11.1 | Widget `Bubble(icon, label, badge, onTap)` dùng chung | `frontend/lib/core/ui.dart` | — |
| F11.2 | `MyAppointmentsScreen`: chuyển `_tile` + danh sách từ home sang, thêm chip lọc Tất cả / Sắp tới / Đã khám / Đã huỷ / Chờ thanh toán, kéo để tải lại | `screens/my_appointments_screen.dart` (mới), `patient_home_screen.dart` | Bấm vào thẻ vẫn mở chi tiết |
| F11.3 | `PaidBillsScreen`: lọc `isPaid`, mỗi dòng hiện ngày, bác sĩ, số tiền đã trả, phương thức; bấm thì mở chi tiết | `screens/paid_bills_screen.dart` (mới) | Chỉ hiện lịch đã thanh toán |
| F11.4 | Home: lời chào + carousel + lưới 6 bubble (có badge) + tin tức. Bỏ FAB | `patient_home_screen.dart` | Mỗi bubble mở đúng màn |
| F11.5 | Bubble "Báo cáo AI": bottom sheet chọn lịch hẹn chưa huỷ, rồi mở `AiReportScreen` | `patient_home_screen.dart` | Không có lịch thì báo "Chưa có lịch khám" |
| F11.6 | Carousel: mũi tên trái/phải, vòng lại ở hai đầu, reset timer khi bấm hoặc vuốt, ẩn khi chỉ có 1 tin. Widget test | `core/news_ui.dart`, `test/news_carousel_test.dart` | `flutter test` pass |

## Phase 12: `admin-nav`

| Mã | Việc | File | Xong khi |
|---|---|---|---|
| F12.1 | Thêm tham số `embedded` (mặc định `false`) cho 3 màn con: `embedded = true` thì không dựng AppBar riêng | `admin_payments_screen.dart`, `admin_disease_screen.dart`, `admin_news_screen.dart` | Mở độc lập vẫn như cũ |
| F12.2 | `AdminHomeScreen`: `NavigationBar` 4 mục + `IndexedStack`. Rộng ≥ 840 px thì dùng `NavigationRail`. Tách phần lương hiện tại thành tab 1 | `admin_home_screen.dart` | Không còn `PopupMenuButton` |
| F12.3 | AppBar: tiêu đề theo tab, chuông có badge, nút Đăng xuất riêng. FAB "Thêm bác sĩ" chỉ hiện ở tab 1 | `admin_home_screen.dart` | — |
| F12.4 | Badge chưa đọc trên chuông **và** mục Thanh toán, `99+`, làm mới khi đổi tab hoặc quay lại từ màn thông báo | `admin_home_screen.dart` | Webhook giả lập (smoke) → badge tăng trong ≤ 15 s |

## Phase 13: `doctor-ui` (sau cổng duyệt)

| Mã | Việc | File | Xong khi |
|---|---|---|---|
| F13.1 | Đầu trang: avatar, tên, 3 thẻ thống kê (Chờ / Đã xác nhận / Đã khám hôm nay) | `doctor_home_screen.dart` | Khớp mockup |
| F13.2 | "Ca làm": nút lớn ở đầu trang hoặc mục `NavigationBar`, theo mockup đã duyệt | `doctor_home_screen.dart` | 1 chạm là mở `DoctorShiftsScreen` |
| F13.3 | Thẻ lịch hẹn gọn lại: hành động chính là nút, hành động phụ gom vào bottom sheet | `doctor_home_screen.dart` | Checklist bên dưới đạt hết |

Checklist hồi quy cho bác sĩ (kiểm tra tay sau F13.3): Xác nhận · Đã khám xong (chọn bệnh) · Dời lịch · Tái khám · Báo cáo AI · Không nhận bệnh (có lý do) · Huỷ lịch (có lý do) · Xem chi tiết · Ca trực · Đăng xuất.

## Phase 14: tài liệu và commit

- `wiki/api-routes.md` (`POST /auth/bhyt-lookup`), `wiki/auth-flow.md`, `wiki/ui-components.md` (`Bubble`, carousel có mũi tên, nav admin), `wiki/patient-module.md`, `wiki/admin-module.md`, `wiki/doctor-module.md`, `wiki/log.md`.
- `spec/README.md`: đánh dấu spec 05 đã triển khai.
- Ảnh trước/sau ở `screenshots/phase-9..13/`.
- Mỗi phase một commit (`feat(auth): bhyt lookup`, `feat(frontend): patient bubbles`…).

## Kiểm tra chung sau mỗi phase

`npm run lint && npm test` (nếu có sửa backend) · `flutter analyze && flutter test` · chụp màn hình khổ 390 px và ≥ 840 px.
