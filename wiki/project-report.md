---
last_updated: 2026-06-03
tags: [report, requirements, vision, use-case, academic]
---

# Báo cáo Đồ án (ĐACN1) — Tóm tắt & đối chiếu

Tóm tắt báo cáo đồ án "**Ứng dụng đặt lịch khám tích hợp tư vấn khám bệnh bằng AI**"
(Thái Văn Quý 23IT227, Dương Đăng Quân; GVHD: TS. Nguyễn Đức Hiển; ĐH CNTT&TT Việt–Hàn).
Nguồn: `docs/Thái Văn Quý-23IT227 Báo cáo ĐACN1 (1).docx` (546 đoạn, 13 bảng).
Bài này ghi lại **tầm nhìn sản phẩm theo báo cáo** và **đối chiếu với phần đã hiện thực**
trong code — vì hai bên lệch nhau đáng kể. Khi làm tính năng mới, dùng bài này để biết
"báo cáo kỳ vọng gì" còn [[project-architecture]] để biết "code thực sự có gì".

## 1. Đề tài & mục tiêu *(đã chốt theo note 2026-06-03)*

App y tế đặt lịch khám có **trợ lý AI**. Luồng AI cốt lõi: bệnh nhân gửi **triệu chứng +
ảnh bệnh** → AI **xem xét, tổng kết chẩn đoán sơ bộ thành một file PDF** → **gửi riêng
cho bác sĩ** để bác sĩ xem trước và đưa ra chẩn đoán chính thức cho bệnh nhân đã gửi PDF
đó. Mục tiêu: hỗ trợ bác sĩ chẩn đoán nhanh hơn, giảm thời gian chờ cho bệnh nhân.

## 2. Phạm vi & công nghệ *(đã chốt theo note 2026-06-03)*

- **Frontend:** Flutter.
- **Backend:** NestJS.
- **CSDL:** PostgreSQL + TypeORM — **không dùng Firebase**.
- **AI — gồm 2 phần:**
  1. **Nhận diện hình ảnh:** bệnh nhân gửi ảnh → AI phân tích, nhận diện đó là bệnh gì.
  2. **Chatbox:** bệnh nhân nhập triệu chứng → match với các bệnh để chẩn đoán dựa theo
     triệu chứng.
  - Hệ thống **tổng hợp** kết quả nhận diện ảnh + triệu chứng → đúc kết thành **file PDF**
    gửi riêng cho bác sĩ xem và chẩn đoán sơ bộ cho bệnh nhân.
  - **Fallback:** nếu không tự train được chatbox thì **gọi API AI ngoài (vd Gemini)** để
    chat rồi tổng kết kết quả.

## 3. Tác nhân (Actors)

| Actor | Vai trò |
| --- | --- |
| **Patient** | Đặt/sửa/xóa/xem lịch khám, sửa thông tin cá nhân, gửi ảnh + triệu chứng cho AI |
| **Doctor** | Xem lịch đã/chưa xác nhận, xác nhận lịch, tái khám, quản lý ca trực |
| **Admin** | Xem số giờ làm của bác sĩ, **tính tiền theo số giờ làm**, thêm bác sĩ mới |
| **AI** | Nhận diện ảnh bệnh, phân tích triệu chứng (chatbox), tổng hợp → PDF gửi bác sĩ |

## 4. Use case *(đã chốt theo note 2026-06-03)*

**Bệnh nhân (Patient):**
- Add / Edit / Delete / List Appointment
- Edit information (sửa thông tin bệnh nhân)

**Bác sĩ (Doctor):**
- List Confirm Appointment / List Unconfirm Appointment
- Add Shift / Delete Shift / Cancel Shift
- ReAppointment (tái khám)
- Confirm Appointment
- List Shift

**Admin:**
- Xem số giờ làm việc của bác sĩ → tính tiền dựa theo số giờ làm
- Thêm bác sĩ mới

## 5. Yêu cầu phi chức năng (theo báo cáo)

- **Hiệu năng:** API phản hồi < 1s, chịu nhiều client đồng thời (NestJS bất đồng bộ).
- **UI/UX:** đặt lịch ≤ 3 bước bấm, tông xanh y tế nhất quán.
- **Bảo mật:** mã hóa mật khẩu một chiều, xác thực/phân quyền (JWT), bảo vệ dữ liệu
  nhạy cảm (CCCD, BHYT, bệnh án) trong PostgreSQL.

## 6. Đối chiếu Báo cáo ↔ Code thực tế

> Chi tiết đầy đủ ở `docs/bao-cao-bo-sung.md` (Phần A). Tóm tắt:

| Hạng mục | Trạng thái |
| --- | --- |
| Đặt lịch / xác nhận / tái khám / ca trực | ✅ Đã có ([[patient-module]], [[doctor-module]]) |
| Kiến trúc NestJS + TypeORM + PostgreSQL | ✅ Khớp ([[project-architecture]], [[database-schema]]) |
| AI: nhận diện ảnh + chatbox + tổng hợp PDF gửi bác sĩ | ❌ Chưa hiện thực (mục tiêu chính) |
| Đăng nhập / phân quyền (JWT) | ❌ Stub rỗng ([[auth-flow]]) |
| Admin: tính tiền theo giờ làm, thêm bác sĩ | ❌ Module rỗng ([[admin-module]]) |
| Frontend Flutter (các màn hình) | ❌ Mới scaffold mặc định ([[ui-components]]) |
| Firebase | ⛔ Không dùng (đã chốt: chỉ PostgreSQL) |
| Video call, SMS/Email | ⛔ **Ngoài phạm vi — không làm** (chốt theo note) |
| Chuyên khoa trong entity | ⛔ **Không cần** (chốt theo note) |

**Kết luận:** mục tiêu chính là **luồng AI (ảnh + triệu chứng → PDF cho bác sĩ)** cộng với
đặt lịch/ca trực/phân quyền. Code hiện mới có **phần lõi backend đặt lịch khám**; AI, Auth,
Admin, Frontend còn phải làm. Video call / SMS-email / chuyên khoa **đã loại khỏi phạm vi**.

Liên quan: [[project-architecture]] · [[database-schema]] · [[api-routes]] ·
[[auth-flow]] · [[admin-module]] · [[known-issues]]
