# Phase 1: ảnh đại diện

Spec: `spec/02-avatar.md` · Phụ thuộc: phase 0

## Hiện trạng
- `PatientEntity.avatar` đã có (varchar NOT NULL, `auth.service.ts:71` đang ghi `""`). Dùng lại cột này.
- Flutter tạo bác sĩ qua `POST /auth/register-doctor` (`frontend/lib/services/admin_service.dart:33`).
- `POST /doctor/create-doctor` (`doctor.controller.ts:39`) không có caller trong Flutter. Sẽ xoá (grep `backend/test/` trước khi xoá).

## Backend

### B1.1 Migration `AddDoctorAvatar`
- `ALTER TABLE doctor ADD COLUMN avatar varchar NOT NULL DEFAULT ''`. Viết đủ `down`.
- `DoctorEntity`: `@Column({ default: '' }) avatar: string;`
- Chạy `npm run typeorm migration:run`.

### B1.2 DTO đăng ký chịu được multipart
- `RegisterDTO.age`, `RegisterDoctorDTO.age`: thêm `@Type(() => Number)` trước `@IsInt()`.

### B1.3 `auth.controller.ts`
- `register`: `@ApiConsumes('multipart/form-data')`, `@UseInterceptors(FileInterceptor('avatar', imageUpload('avatars')))`, nhận `@UploadedFile() avatar?`.
- `register-doctor`: tương tự, nhưng không có file thì trả `BadRequestException('Bác sĩ phải có ảnh đại diện')`.
- Bọc lời gọi service trong `try { … } catch (e) { await removeUpload(path); throw e; }` để email trùng hay lỗi DB không để lại file rác.

### B1.4 `auth.service.ts`
- `register(dto, avatarPath)` lưu `avatar: avatarPath`. `registerDoctor(dto, avatarPath)` lưu tương tự.
- `sign(account)` trả thêm `name` và `avatarUrl` (`null` nếu `''`). Load relation `patient`/`doctor` khi login. Admin trả `name: 'Admin'`, `avatarUrl: null`.

### B1.5 Trả `avatarUrl` ở các endpoint đọc
- `/doctor/list`, `/doctor/detail/:id`, `/patient/me`, chi tiết appointment ở cả hai phía (relation `doctor`/`patient` đã được load). Entity đã có cột `avatar`. Cách đơn giản nhất: Flutter đọc key `avatar` của entity trả về. Chỉ response của login/register (B1.4) dùng key `avatarUrl`.
  - Ghi vào wiki: response login dùng `avatarUrl`, response entity dùng `avatar`.

### B1.6 Xoá `POST /doctor/create-doctor` và DTO đi kèm nếu không còn ai dùng.

## Frontend

### F1.1 Model + lưu trữ
- `models/auth_result.dart`: thêm `name`, `avatarUrl`.
- `core/token_store.dart`: `write` thêm `name`, `avatarUrl`. Thêm `readName()` và `readAvatarUrl()`. `clear()` xoá luôn 2 key này.
- `providers/auth_provider.dart`: expose `name`, `avatarUrl`, khôi phục từ `token_store` khi khởi động.
- Model `doctor.dart`, `patient.dart`, `doctor_detail.dart`: thêm `avatar` (`String?`).

### F1.2 Service gửi multipart
- `auth_service.register(..., XFile? avatar)`: dùng `FormData.fromMap({...fields, if (avatar != null) 'avatar': MultipartFile.fromBytes(await avatar.readAsBytes(), filename: avatar.name)})`. Dùng `fromBytes` để chạy được trên web, theo pattern của `services/ai_service.dart`.
- `admin_service` tạo bác sĩ: tương tự, avatar bắt buộc.

### F1.3 Màn hình
- `register_screen.dart`: vòng tròn avatar ở đầu form, bấm vào thì gọi `ImagePicker().pickImage(source: gallery, maxWidth: 1024, imageQuality: 85)`. Preview bằng `Image.memory`. Có nút xoá ảnh đã chọn.
- `add_doctor_screen.dart`: giống trên. Nút "Tạo" disabled khi chưa có ảnh, kèm dòng lỗi đỏ.
- `patient_home_screen.dart`, `doctor_home_screen.dart`, `admin_home_screen.dart`: AppBar có `UserAvatar` + "Xin chào, {name}".
- `create_appointment_screen.dart`: mỗi bác sĩ có `UserAvatar(radius: 24)` ở đầu dòng. Bác sĩ đang chọn hiện ảnh to hơn (radius 40).
- `appointment_detail_screen.dart` có ảnh bác sĩ. `doctor_appointment_detail_screen.dart` có ảnh bệnh nhân. `admin_doctor_detail_screen.dart` có ảnh bác sĩ.

## Kiểm tra
- Smoke gửi multipart bằng `FormData` + `Blob` có sẵn trong Node 18+, không thêm package.
- [ ] Thêm vào `backend/test/api-smoke.mjs` các case: register không ảnh trả 201; register có ảnh thì `avatarUrl` có giá trị và GET URL đó trả 200; register-doctor không ảnh trả 400; register email trùng có ảnh thì số file trong `uploads/avatars` không tăng.
- [ ] `npm run test:e2e` pass. `test/patient-flow.e2e-spec.ts` có thể phải chuyển register sang `.field()`.
- [ ] Tay: đăng ký có ảnh, login thấy ảnh ở header, kill app mở lại vẫn thấy. Đặt lịch thấy ảnh bác sĩ. Bác sĩ cũ (avatar `''`) hiện chữ cái đầu.
- [ ] `npm run lint`, `npm test`, `flutter analyze` sạch.
