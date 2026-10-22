# 02. Ảnh đại diện

## Mục tiêu

| Ai | Khi nào | Bắt buộc? |
|----|---------|-----------|
| Bệnh nhân | Tự đăng ký (`/auth/register`) | **Không**. Không chọn thì hiện avatar mặc định (chữ cái đầu của tên) |
| Bác sĩ | Admin tạo bác sĩ | **Có**, để nhận diện bác sĩ |

Avatar hiển thị ở:
1. Header trang chủ của người đang đăng nhập (cả 3 role. Admin không có ảnh nên dùng chữ cái đầu).
2. Danh sách chọn bác sĩ khi đặt lịch (`create_appointment_screen.dart`) và màn chi tiết bác sĩ.
3. Chi tiết lịch hẹn: bệnh nhân thấy ảnh bác sĩ, bác sĩ thấy ảnh bệnh nhân.
4. Admin: danh sách bác sĩ và chi tiết bác sĩ.

## Hiện trạng
- `PatientEntity.avatar` **đã có** (varchar NOT NULL, đang lưu `""`). Dùng lại cột này, không tạo cột mới.
- `DoctorEntity` **chưa có** avatar.
- Có **2 route tạo bác sĩ**: `POST /auth/register-doctor` (admin, Flutter đang dùng) và `POST /doctor/create-doctor`. **Đã chốt:** giữ `/auth/register-doctor` (bắt buộc avatar), **xoá** `/doctor/create-doctor` (route này cho mọi user đã login tạo một bác sĩ hard-code).

## Backend

### Schema (migration `AddDoctorAvatar`)
- `doctor.avatar varchar NOT NULL DEFAULT ''`. Bác sĩ cũ sẽ có `''` và hiện chữ cái đầu. Không bắt admin upload lại.
- Giá trị lưu là đường dẫn tương đối `/uploads/avatars/<uuid>.<ext>`, hoặc `''` nếu không có ảnh.

### API
| Route | Thay đổi |
|-------|----------|
| `POST /auth/register` (public) | Chuyển sang `multipart/form-data`, thêm field file `avatar` **tuỳ chọn** |
| Route tạo bác sĩ (admin) | Chuyển sang `multipart/form-data`, field `avatar` **bắt buộc**. Thiếu ảnh thì trả 400 `"Bác sĩ phải có ảnh đại diện"` |
| Response login/register | Thêm `name` và `avatarUrl` (`null` nếu rỗng). Admin trả `name: "Admin"`, `avatarUrl: null` |
| `GET /doctor/list`, chi tiết bác sĩ, chi tiết appointment, `/patient/me`, `/admin/doctor-salaries` | Trả thêm cột `avatar` (entity) |

Lưu ý khi chuyển DTO sang multipart: mọi field gửi lên đều là string, nên `age` cần `@Type(() => Number)` để `@IsInt()` vẫn pass (đã bật `transform: true`).

Endpoint `register` là public và nhận file, nên giữ giới hạn 2 MB + mimetype như README. Rate-limit thì để sau (không cài thêm `@nestjs/throttler` lúc này).

### Đổi tên field (để thống nhất)
DB giữ cột `avatar` (path, `''` = không có). **Đã chốt khi code:** chỉ response login/register dùng key `avatarUrl` (`null` nếu không có); các response trả entity giữ nguyên key **`avatar`**. Cả hai đều là path tương đối, Flutter tự ghép `ApiConfig.baseUrl + path`.

## Frontend

- **Một widget dùng chung** `UserAvatar({String? avatarUrl, required String name, double radius})` trong `core/ui.dart`. Có URL thì dùng `CircleAvatar(backgroundImage: NetworkImage(...))`, không có hoặc ảnh lỗi thì hiện chữ cái đầu của `name`. Mọi chỗ hiển thị avatar đều dùng widget này.
- `register_screen.dart`: thêm vòng tròn avatar ở đầu form, bấm vào thì mở `ImagePicker` (gallery), chọn xong preview ngay. Có nút "x" để bỏ chọn.
- `add_doctor_screen.dart`: tương tự, nhưng chưa có ảnh thì nút "Tạo" disabled và hiện dòng lỗi "Cần chọn ảnh đại diện".
- `AuthResult`: thêm `name`, `avatarUrl`. `token_store.dart` lưu thêm 2 giá trị này để mở lại app vẫn có avatar mà không cần gọi API.
- Header các home screen: `UserAvatar` + "Xin chào, {name}".
- `create_appointment_screen.dart`: mỗi bác sĩ trong danh sách có `UserAvatar` (radius ~24). Bác sĩ đang chọn hiện ảnh lớn hơn kèm tên.

## Tiêu chí nghiệm thu
- [ ] Đăng ký bệnh nhân không chọn ảnh vẫn thành công, header hiện chữ cái đầu.
- [ ] Đăng ký bệnh nhân có ảnh thì login thấy ảnh ở header. Tắt app mở lại vẫn thấy.
- [ ] Admin tạo bác sĩ không có ảnh thì nhận 400, không tạo account/doctor, không có file rác.
- [ ] Đăng ký với email trùng nhưng có kèm ảnh thì nhận 409/400 và file ảnh vừa upload bị xoá.
- [ ] Bệnh nhân đặt lịch thấy ảnh từng bác sĩ trong danh sách chọn.
- [ ] Bác sĩ cũ (avatar `''`) vẫn hiển thị được (chữ cái đầu), không crash.
