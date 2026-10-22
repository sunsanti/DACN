# 05. Làm mới giao diện: bubble bệnh nhân, tra BHYT khi đăng ký, điều hướng admin, giao diện bác sĩ

Ngày: 2026-10-22 · Trạng thái: **Bản nháp, chờ duyệt** · Nguồn: `note.txt` · Plan: [`plans/05-ui-revamp.md`](../plans/05-ui-revamp.md) · Tiến độ: `TODO.md` (Phase 9–14)

## 1. Mục tiêu

Làm app dễ dùng hơn cho cả 3 vai mà **không đổi nghiệp vụ**. Chỉ một chỗ cần backend mới (tra BHYT trước khi đăng ký), còn lại chỉ sửa Flutter.

Yêu cầu gốc (`note.txt`) → mô-đun:

| # | Yêu cầu | Mô-đun |
|---|---------|--------|
| P1 | Bubble + icon trên trang bệnh nhân, mỗi bubble là một chức năng (đặt lịch, xem lịch hẹn, hoá đơn đã trả…) | `patient-home` |
| P2 | Carousel có mũi tên trái/phải để lướt | `patient-home` |
| P3 | Danh sách lịch khám chuyển sang màn hình riêng, mở bằng bubble | `patient-home` |
| P4 | Ô BHYT màu xám, không sửa được. Nhập CCCD xong thì tra BHYT, có thẻ thì hiện vào ô | `register-bhyt` |
| A1 | Bỏ menu 3 chấm, chia thành các mục bấm vào được | `admin-nav` |
| A2 | Hiện số thông báo chưa đọc | `admin-nav` |
| D1 | Cải thiện giao diện bác sĩ theo template (cho xem trước) | `doctor-ui` |
| D2 | "Ca làm" thành nút/mục nổi bật, hợp template | `doctor-ui` |
| U1 | Tìm template cho cả 3 vai, gửi link + ảnh minh hoạ vào `pre_implement/` **trước khi code** | `ui-preview` |

## 2. Bản đồ mô-đun

| Mô-đun | Phạm vi | Phụ thuộc |
|---|---|---|
| `ui-preview` | Tìm template, chọn bảng màu/khung chung, mockup 3 vai trong `pre_implement/` | — |
| `register-bhyt` | Endpoint public tra BHYT + ô BHYT ở màn đăng ký | — (độc lập với giao diện) |
| `patient-home` | Lưới bubble, màn "Lịch hẹn", màn "Hoá đơn đã trả", mũi tên carousel | `ui-preview` duyệt |
| `admin-nav` | Thanh điều hướng thay menu 3 chấm, badge chưa đọc | `ui-preview` duyệt |
| `doctor-ui` | Bố cục lại màn bác sĩ, nút "Ca làm" | `ui-preview` duyệt (bắt buộc theo note) |

Thứ tự: `ui-preview` ∥ `register-bhyt` → **cổng duyệt** → `patient-home` ∥ `admin-nav` → `doctor-ui`.

## 3. Đặc tả từng mô-đun

### 3.1 `ui-preview`: template và mockup (cổng duyệt)

- Tìm **2–3 template** cho app đặt lịch khám (Figma Community, Dribbble/Behance, hoặc Flutter UI kit mã nguồn mở). Mỗi template ghi: link, giấy phép, lý do chọn.
- Tạo `pre_implement/` gồm:
  ```
  pre_implement/
    README.md            → link template, so sánh, phương án đề xuất, chỗ để bạn ghi ý kiến
    patient-home.png     → lưới bubble + carousel có mũi tên
    patient-register.png → ô BHYT xám (có thẻ / không có thẻ)
    admin-home.png       → thanh điều hướng + badge
    doctor-home.png      → bố cục mới + nút Ca làm
  ```
- Mockup vẽ **lại theo app thật** (đúng chữ tiếng Việt, đúng chức năng hiện có), không chỉ là ảnh chụp template.
- **Không code giao diện** (`patient-home`, `admin-nav`, `doctor-ui`) trước khi bạn duyệt `pre_implement/README.md`.

### 3.2 `register-bhyt`: tra BHYT khi đăng ký

**Backend.** Thêm route mới `POST /auth/bhyt-lookup`, gắn `@Public()` vì người dùng chưa có tài khoản.
```
Request:  { "cccd": "079012345689", "birthDate": "2000-01-01" }
200 có thẻ:     { "found": true, "cardNumber": "DN4******1234", "rate": 0.8, "validTo": "2026-12-31", "status": "valid" }   // status: valid | expired | not_yet_valid
200 không thẻ:  { "found": false }
400: CCCD sai định dạng (khác 12 số) hoặc ngày sinh sai định dạng
```
- Dùng lại `BhytService.findCard(cccd, birthDate)`. Hàm này đã bắt ngày sinh phải khớp, nên **chỉ có CCCD thì không tra được** thẻ của người khác.
- **Che mã thẻ** khi trả về (chỉ giữ 3 ký tự đầu và 4 ký tự cuối). Không ghi log CCCD.
- Không ghi gì vào DB. `bhyt_registry` vẫn chỉ đọc.
- Giới hạn tần suất: **10 request / phút / IP** cho riêng route này để tránh dò CCCD (xem Q3).

**Flutter** (`register_screen.dart`):
- Đặt ô **"Thẻ BHYT"** ngay dưới ô Ngày sinh: `enabled: false`, nền xám nhạt (`fillColor` = `surfaceContainerHighest`), không focus được.
- Tự tra khi **CCCD đủ 12 số** và **người dùng đã tự chọn ngày sinh**. Chờ 400 ms sau lần gõ cuối mới gọi API, và bỏ kết quả của request cũ nếu người dùng gõ tiếp.
- Trạng thái của ô:

  | Tình huống | Nội dung ô |
  |---|---|
  | Chưa đủ CCCD hoặc chưa chọn ngày sinh | trống, gợi ý "Nhập CCCD và ngày sinh để tra" |
  | Đang tra | vòng xoay nhỏ ở cuối ô |
  | Có thẻ, còn hạn | `DN4******1234 · 80% · HSD 31/12/2026` |
  | Có thẻ, hết hạn | như trên kèm chữ đỏ "đã hết hạn" |
  | Không có thẻ | "Không tìm thấy thẻ BHYT" (chữ xám) |
  | Lỗi mạng | "Không tra được, thử lại sau". **Không chặn** việc đăng ký |

- Ô này chỉ để hiển thị. Lúc đăng ký, server vẫn tự tra lại như hiện nay, client không gửi thông tin BHYT lên.

### 3.3 `patient-home`: bubble, màn Lịch hẹn, mũi tên carousel

**Trang chủ bệnh nhân**, từ trên xuống: lời chào + avatar → carousel tin tức → lưới bubble → danh sách tin tức.

Các bubble (hình tròn có icon, chữ bên dưới, 3 cột trên điện thoại):

| Bubble | Icon | Mở |
|---|---|---|
| Đặt lịch khám | `add_circle` / `calendar_month` | `CreateAppointmentScreen` (có sẵn) |
| Lịch hẹn của tôi | `event_note` | **Mới:** `MyAppointmentsScreen` (đưa danh sách đang có trên home vào đây) |
| Hoá đơn đã trả | `receipt_long` | **Mới:** `PaidBillsScreen`, lọc `appointments.where(isPaid)` ở client, bấm vào thì mở chi tiết lịch hẹn |
| Chờ thanh toán | `payments` | Dùng lại `MyAppointmentsScreen`, lọc `hasBill && !isPaid` |
| Báo cáo AI | `smart_toy` | Chọn một lịch hẹn chưa huỷ → `AiReportScreen` |
| Hồ sơ | `person` | `ProfileScreen` (có sẵn) |

- Bubble "Lịch hẹn" và "Chờ thanh toán" có **badge số lượng** (số lịch sắp tới, số hoá đơn chưa trả).
- Bỏ FAB "Đặt lịch" vì đã có bubble. Nút "Đăng xuất" giữ ở AppBar.
- `MyAppointmentsScreen` dùng lại `_tile` hiện tại. Có kéo để tải lại, và có chip lọc: Tất cả / Sắp tới / Đã khám / Đã huỷ.

**Carousel** (`core/news_ui.dart`, `NewsCarousel`):
- Thêm 2 nút tròn mờ `chevron_left` / `chevron_right` ở hai mép, căn giữa theo chiều dọc. Bấm thì `animateToPage` ±1, vòng lại ở hai đầu.
- Bấm mũi tên hoặc vuốt tay sẽ **reset bộ đếm auto-play 5 s** để slide không nhảy ngay sau khi bấm.
- Chỉ có 1 tin thì ẩn mũi tên. Mỗi nút có `tooltip` ("Tin trước" / "Tin sau") cho trình đọc màn hình.

### 3.4 `admin-nav`: thanh điều hướng + badge

- Thay `PopupMenuButton` bằng **`NavigationBar`** (Material 3, có sẵn) gồm 4 mục: **Bác sĩ & lương** · **Thanh toán** · **Bảng giá** · **Tin tức**. Mỗi mục là một màn hình hiện có, giữ trạng thái bằng `IndexedStack`.
- Khi chiều rộng ≥ 840 px (web/tablet), đổi sang `NavigationRail` bên trái. Đây là breakpoint chuẩn của Material, không thêm thư viện.
- AppBar còn: tiêu đề của mục đang mở, chuông thông báo, nút Đăng xuất (icon riêng, không nằm trong menu).
- **Badge chưa đọc:** hiện **cả trên chuông và trên mục "Thanh toán"**, lấy từ `GET /admin/notifications/unread-count` (đã có, đang hỏi lại mỗi 15 s). Mở màn thông báo hay quay lại từ đó đều làm mới badge. Số lớn hơn 99 thì hiện `99+`.
- Ba màn con hiện đang có `Scaffold` + AppBar riêng. Khi nhúng vào tab thì bỏ AppBar trùng, nhưng **vẫn mở được độc lập** bằng cách thêm tham số `embedded`.

### 3.5 `doctor-ui`: bố cục lại theo template

Chỉ bắt đầu sau khi `pre_implement/doctor-home.png` được duyệt. Hướng đề xuất (sẽ chỉnh theo template được chọn):
- Đầu trang: avatar + tên bác sĩ + **thẻ thống kê hôm nay** (số lịch chờ, đã xác nhận, đã khám).
- **"Ca làm"** chuyển từ icon nhỏ trên AppBar thành một thẻ hoặc nút lớn ở đầu trang ("Ca làm của tôi →"), hoặc thành một mục của `NavigationBar` (Lịch hẹn · Ca làm), tuỳ template.
- Danh sách lịch hẹn giữ 3 tab Chờ / Đã xác nhận / Đã khám. Mỗi thẻ gọn hơn: hành động chính (Xác nhận / Đã khám xong) là nút, các hành động phụ (Dời lịch, Tái khám, Báo cáo AI, Huỷ) gom vào bottom sheet.
- Không đổi luồng nghiệp vụ hay API. Các nút đỏ (Huỷ / Không nhận bệnh) vẫn phải xác nhận lại như hiện nay.

## 4. Tech stack

Flutter (Material 3, Provider, dio), NestJS 11. **Không thêm thư viện Flutter mới.** Bubble, mũi tên, NavigationBar/Rail, badge và lớp phủ đều có sẵn trong Material. Backend có thể cần `@nestjs/throttler` (xem Q3).

## 5. Lệnh

```bash
# backend/
npm run lint && npm test
npx jest src/auth                       # test cho bhyt-lookup
node test/api-smoke.mjs                 # cần API :3000 + AI :8000 đang chạy
# frontend/
flutter analyze && flutter test
flutter run -d chrome                   # chụp màn hình kiểm tra
```

## 6. Cấu trúc file dự kiến

```
backend/src/auth/auth.controller.ts        + POST /auth/bhyt-lookup
backend/src/auth/dto/bhyt-lookup.dto.ts    mới
backend/src/billing/bhyt.service.ts        + maskCardNumber (nếu chưa có)
frontend/lib/screens/register_screen.dart  ô BHYT
frontend/lib/services/auth_service.dart    + bhytLookup()
frontend/lib/screens/patient_home_screen.dart   lưới bubble
frontend/lib/screens/my_appointments_screen.dart mới
frontend/lib/screens/paid_bills_screen.dart      mới
frontend/lib/core/ui.dart                  + widget Bubble (dùng chung cho bệnh nhân / bác sĩ)
frontend/lib/core/news_ui.dart             mũi tên carousel
frontend/lib/screens/admin_home_screen.dart      NavigationBar/Rail
frontend/lib/screens/admin_{payments,disease,news}_screen.dart  tham số embedded
frontend/lib/screens/doctor_home_screen.dart     bố cục mới
pre_implement/                             mockup + README (được commit)
```

## 7. Phong cách code

Theo code hiện tại: widget nhỏ là `StatelessWidget` trong `core/ui.dart`, chuỗi giao diện viết thẳng bằng tiếng Việt, màu lấy từ `Theme.of(context).colorScheme`, không hard-code mã màu.
```dart
class Bubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;
  const Bubble(this.icon, this.label, {super.key, this.badge = 0, required this.onTap});
  // CircleAvatar(primaryContainer) + Badge(isLabelVisible: badge > 0) + Text(label)
}
```

## 8. Kiểm thử

- **Backend:** unit test cho `bhyt-lookup`, gồm các ca: có thẻ / sai ngày sinh → `found:false` / CCCD 11 số → 400 / mã thẻ đã được che. Thêm 1 bước vào `test/api-smoke.mjs`.
- **Frontend:** `flutter analyze` sạch. Widget test cho `NewsCarousel` (bấm mũi tên phải → sang trang 1, ở trang cuối thì vòng về 0) và cho lọc `PaidBillsScreen`.
- **Thủ công:** chụp màn hình trước/sau cho mỗi mô-đun vào `screenshots/phase-9..13/`, ở 2 khổ: điện thoại 390 px và web ≥ 840 px.

## 9. Ranh giới

- **Luôn làm:** giữ nguyên `confirmCondition` (1 chờ / 0 xác nhận / 2 đã khám). Mọi route mới có DTO validate. Cập nhật wiki theo `wiki/wiki-triggers.md`. Chạy lint/test trước khi commit.
- **Hỏi trước:** thêm dependency (`@nestjs/throttler`), đổi schema DB (spec này **không** cần migration), đổi bảng màu/theme chung trong `main.dart`.
- **Không bao giờ:** trả mã thẻ BHYT hoặc CCCD đầy đủ qua route public, ghi log CCCD, cho client gửi thông tin BHYT lúc đăng ký, code giao diện trước khi `pre_implement/` được duyệt.

## 10. Tiêu chí hoàn thành

1. `pre_implement/` có README với ≥ 2 link template và 4 ảnh mockup, đã được bạn duyệt.
2. Đăng ký với CCCD + ngày sinh có trong `bhyt_registry`: ô xám hiện mã che + mức hưởng + hạn thẻ trong ≤ 1 s. Sai ngày sinh hoặc CCCD lạ: hiện "Không tìm thấy thẻ BHYT". Ô không sửa được.
3. Gọi `POST /auth/bhyt-lookup` quá 10 lần/phút từ một IP thì bị trả 429.
4. Trang chủ bệnh nhân không còn danh sách lịch: có ≥ 5 bubble, mỗi bubble mở đúng màn hình. "Hoá đơn đã trả" chỉ hiện lịch hẹn `paymentStatus = paid`.
5. Carousel có mũi tên 2 bên, bấm thì chuyển slide và vòng lại ở hai đầu. Có 1 tin thì không hiện mũi tên.
6. Admin không còn menu 3 chấm. 4 mục bấm được, Đăng xuất là nút riêng. Badge chưa đọc hiện trên chuông và mục Thanh toán, cập nhật trong ≤ 15 s.
7. Màn bác sĩ khớp mockup đã duyệt, "Ca làm" mở được bằng 1 chạm từ trang đầu. Mọi hành động cũ vẫn chạy (đối chiếu checklist trong plan).
8. `npm run lint`, `npm test`, `flutter analyze`, `flutter test` đều sạch.

## 11. Câu hỏi mở (đang theo phương án in đậm nếu bạn không đổi)

- **Q1.** Ô BHYT chỉ ở màn **đăng ký** hay cả màn hồ sơ? Hồ sơ hiện đã hiện mã BHYT chỉ đọc theo spec 04. → **Chỉ màn đăng ký.**
- **Q2.** Tra BHYT cần **CCCD + ngày sinh** (để không ai dò được thẻ chỉ bằng CCCD). Note ghi "điền CCCD là check", nghĩa là chỉ CCCD. → **CCCD + ngày sinh**, tự tra khi đủ cả hai.
- **Q3.** Giới hạn tần suất: thêm `@nestjs/throttler` (thư viện chính thức của Nest) hay tự viết bộ đếm trong bộ nhớ (~15 dòng, mất khi restart)? → **`@nestjs/throttler`, chỉ áp cho route này.**
- **Q4.** Bubble nào cần có? Đề xuất 6 bubble ở mục 3.3. Bỏ hoặc thêm bubble nào? → **Giữ 6.**
- **Q5.** Badge chưa đọc của admin hiện **đã có** trên chuông (chỉ đếm thông báo thanh toán). Bạn không thấy badge, hay muốn đếm thêm loại thông báo khác? → **Giữ nguồn đếm hiện tại, hiện thêm trên mục Thanh toán.**
- **Q6.** Admin: `NavigationBar` dưới đáy (đề xuất) hay lưới thẻ ở trang chủ admin? → **NavigationBar, đổi sang Rail khi màn rộng.**
