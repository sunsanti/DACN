# Spec: tin tức, ảnh đại diện, bảo hiểm y tế

Ngày: 2026-10-04 · Trạng thái: **Đã chốt và đã triển khai** (2026-10-04). Kế hoạch: `plans/`, tiến độ: `TODO.md`

## Phạm vi

| # | Tính năng | File spec |
|---|-----------|-----------|
| 1 | Carousel + danh sách tin tức sức khoẻ / bệnh viện. Admin thêm link kèm ảnh đại diện | [01-news.md](01-news.md) |
| 2 | Ảnh đại diện: bệnh nhân chọn khi đăng ký (tuỳ chọn), bác sĩ bắt buộc. Hiện avatar sau khi login và khi chọn bác sĩ | [02-avatar.md](02-avatar.md) |
| 3 | Bảo hiểm y tế (BHYT): khai báo thẻ, tính số tiền được BHYT chi trả và số tiền bệnh nhân phải trả | [03-insurance.md](03-insurance.md) |
| 4 | **(Đã triển khai)** CCCD bắt buộc khi đăng ký → tự gắn BHYT; dịch vụ đánh dấu được BHYT chi trả; thanh toán tiền mặt / QR. **Thay phần khai thẻ của spec 3** | [04-cccd-bhyt-payment.md](04-cccd-bhyt-payment.md) |
| 5 | **(Chờ duyệt)** Làm mới giao diện: bubble bệnh nhân + màn Lịch hẹn/Hoá đơn, mũi tên carousel, tra BHYT khi đăng ký, thanh điều hướng admin + badge, giao diện bác sĩ theo template | [05-ui-revamp.md](05-ui-revamp.md) |

## Quyết định chung (áp dụng cho cả 3 tính năng)

1. **Lưu ảnh trên đĩa, không lưu trong DB.** File nằm ở `backend/uploads/` (thêm vào `.gitignore`). NestJS serve thư mục này tại `/uploads/*` bằng `app.useStaticAssets()` (có sẵn trong `@nestjs/platform-express`). DB chỉ lưu đường dẫn tương đối, ví dụ `/uploads/avatars/3f2a…c1.jpg`.
   - Lý do: Flutter hiện ảnh bằng `Image.network(apiBase + path)`, không cần endpoint riêng và không phải gửi JWT. PDF vẫn để `bytea` như cũ.
   - Hệ quả: ảnh ở `/uploads` **không cần JWT** vì static assets đi ngoài guard. Tên file là UUID ngẫu nhiên nên không đoán được. Với avatar và ảnh tin tức thì chấp nhận được, nhưng **không** dùng thư mục này cho dữ liệu y tế.
2. **Upload dùng multer** (`FileInterceptor`, đã dùng ở `ai.controller.ts`) với `diskStorage`. Ràng buộc chung cho mọi ảnh:
   - Chỉ nhận `image/jpeg`, `image/png`, `image/webp` (kiểm tra mimetype qua `fileFilter`).
   - Tối đa **2 MB** (`limits.fileSize`).
   - Server tự đặt tên file `randomUUID() + ext`. Không bao giờ dùng `originalname` (tránh path traversal).
   - Nếu request lỗi sau khi file đã ghi (validate DTO fail, email trùng…) thì phải xoá file vừa ghi.
   - Viết helper này **một lần** ở `src/common/upload.ts` (multer options + hàm `toPublicPath`) để cả 3 tính năng cùng dùng.
3. **Mọi thay đổi schema đều qua migration** (`synchronize: false`). Entity mới phải được thêm vào `data-source.ts`.
4. **Flutter:** chọn ảnh bằng `image_picker` (đã có). Gửi `MultipartFile.fromBytes` để chạy được cả trên web. Chỉ thêm **một** dependency mới là `url_launcher` để mở link tin tức. Carousel dùng `PageView` có sẵn, không thêm thư viện carousel.
5. **Wiki:** sau khi code xong, cập nhật `wiki/api-routes.md`, `wiki/database-schema.md` và các module tương ứng theo `wiki/wiki-triggers.md`.

## Thứ tự làm đề xuất

1. `common/upload.ts` + static `/uploads` (nền cho mọi thứ)
2. Avatar (02): sửa luồng đăng ký có sẵn, rủi ro thấp
3. News (01): module mới, độc lập
4. Insurance (03): đụng tới luồng đặt lịch, làm cuối

## Ngoài phạm vi

- Thanh toán online. Spec 03 chỉ **tính và hiển thị** số tiền, không thu tiền.
- Tra cứu thẻ BHYT thật với cổng BHXH (không có API công khai). Hệ thống tin vào dữ liệu bệnh nhân khai, bác sĩ đối chiếu thẻ thật khi khám.
- Đổi avatar sau khi đăng ký, crop/resize ảnh, CDN.

## Câu hỏi đã chốt

- [x] Q1 — Giá khám: **phí khám cố định** cho mọi lượt (env `EXAM_FEE`, mặc định 150.000 đ) + **giá theo từng bệnh/dịch vụ** do admin thiết lập trước. **Bác sĩ chọn bệnh khi gửi chẩn đoán** (bấm "Hoàn thành"), được chọn **nhiều** bệnh. Xem [03-insurance.md](03-insurance.md).
- [x] Q2 — Không phân biệt đúng/trái tuyến. Thẻ còn hạn vào ngày khám là được hưởng theo mức trên thẻ.
- [x] Q3 — Tin tức chỉ hiện ở màn hình bệnh nhân.
