# Plan triển khai: tin tức, ảnh đại diện, BHYT + bảng giá

Ngày: 2026-10-04 · Nguồn: `spec/` (README, 01-news, 02-avatar, 03-insurance)

## Quyết định đã chốt (ghi đè spec nếu mâu thuẫn)

| # | Câu hỏi | Đáp án | Ảnh hưởng tới spec |
|---|---------|--------|---------------|
| Q1 | Giá khám | **Phí khám cố định** (env `EXAM_FEE`, mặc định 150.000) + **giá theo từng bệnh** do admin thiết lập trước. **Bác sĩ chọn bệnh khi gửi chẩn đoán** (bấm "Hoàn thành"). Bệnh nhân thấy phí khám, giá bệnh/dịch vụ, phần BHYT trừ và số tiền còn phải trả | Spec 03: bỏ `doctor.examFee`, bỏ `/patient/quote`, bỏ tính lại khi reschedule. Tiền được tính ở bước complete |
| Q2 | Đúng/trái tuyến | Không phân biệt. Thẻ còn hạn vào ngày khám là được hưởng theo mức trên thẻ | Giữ nguyên |
| Q3 | Tin tức hiện ở đâu | Chỉ ở màn hình bệnh nhân | Giữ nguyên |

## Quyết định Claude tự chốt (cần bạn duyệt)

Các điểm dưới đây chưa được hỏi. Plan đang làm theo cột "Đang chọn". Muốn đổi thì ghi vào cột "Ý bạn" rồi plan 03 sẽ được sửa theo.

| # | Quyết định | Đang chọn | Lý do | Nếu đổi thì sao | Vị trí trong plan | Ý bạn |
|---|-----------|-----------|-------|-----------------|-------------------|-------|
| D1 | Mỗi lịch hẹn chọn mấy bệnh? | **Nhiều** bệnh/dịch vụ (ít nhất 1) | Một lượt khám có thể có nhiều bệnh hoặc dịch vụ. Hoá đơn lưu từng dòng trong bảng `appointment_item` (tên, giá) | — | `03-insurance-pricing.md` B3.2, B3.5, F3.3 | **Đã chốt: nhiều bệnh** |
| D2 | Admin có xoá được bệnh không? | **Không**, chỉ tắt (`active=false`) | Giữ lịch sử bảng giá. Bệnh đã tắt không hiện cho bác sĩ chọn nữa | Cho xoá: thêm `DELETE /diseases/:id`. Hoá đơn cũ vẫn an toàn vì lưu tên + giá dạng text | `03-insurance-pricing.md` B3.3 | |
| D3 | Bác sĩ bắt buộc chọn bệnh khi bấm "Hoàn thành"? | **Có** | Lượt khám nào cũng có hoá đơn | Không bắt buộc: không chọn thì chỉ tính phí khám cố định (`items` rỗng) | `03-insurance-pricing.md` luồng bước 4, B3.5, phần Kiểm tra | |

## Các phase

| Phase | File | Phụ thuộc | Commit gợi ý |
|-------|------|-----------|--------------|
| 0 | [00-foundation.md](00-foundation.md): upload ảnh + static `/uploads` + `UserAvatar` | — | `feat(upload): image upload helper + static uploads` |
| 1 | [01-avatar.md](01-avatar.md): avatar bệnh nhân/bác sĩ | 0 | `feat(auth): avatars` · `feat(frontend): avatars` |
| 2 | [02-news.md](02-news.md): tin tức + carousel | 0 | `feat(news): …` · `feat(frontend): news carousel` |
| 3 | [03-insurance-pricing.md](03-insurance-pricing.md): BHYT + bảng giá bệnh + hoá đơn | (1 vì sửa chung `RegisterDTO`) | `feat(billing): …` · `feat(frontend): …` |
| 5–8 | [04-cccd-bhyt-payment.md](04-cccd-bhyt-payment.md): CCCD → BHYT tự động, dịch vụ BHYT, thanh toán tiền mặt / VietQR + webhook SePay, thông báo admin, animation thành công | 3 | `feat(payment): …` · `feat(frontend): payment` |
| 9–14 | [05-ui-revamp.md](05-ui-revamp.md): template + mockup (cổng duyệt), tra BHYT khi đăng ký, bubble bệnh nhân, nav admin, giao diện bác sĩ | 8 | `feat(auth): bhyt lookup` · `feat(frontend): …` |

Phase 1 và 2 độc lập với nhau. Phase 3 làm cuối vì nó sửa `RegisterDTO` (đã được phase 1 chuyển sang multipart) và luồng complete của bác sĩ.

## Quy tắc chung khi code
- `synchronize: false`: mọi thay đổi schema đều qua migration trong `backend/src/migrations/`. Entity mới phải thêm vào `backend/src/data-source.ts`.
- Route mới đều cần JWT. Gắn `@Roles(...)` đúng role. Thao tác trên dữ liệu của người khác thì phải có kiểm tra quyền sở hữu (`assertOwns`).
- Sau mỗi phase chạy: `npm run lint`, `npm test`, `node test/api-smoke.mjs` (backend), `flutter analyze` (frontend).
- `confirmCondition`: 1 = chờ, 0 = đã xác nhận, 2 = đã khám. Không đảo ngược.

## Wiki cần cập nhật sau khi xong (theo `wiki/wiki-triggers.md`)
- `wiki/api-routes.md`: route mới `/news`, `/diseases`, `/patient/me/insurance`. Sửa: register, register-doctor, complete. Xoá: `/doctor/create-doctor`.
- `wiki/database-schema.md`: bảng `news`, `disease`, `appointment_item`. Cột mới trên `doctor`, `patient`, `appointment`.
- `wiki/auth-flow.md` (register multipart, response login có `name`/`avatarUrl`), `wiki/doctor-module.md`, `wiki/patient-module.md`, `wiki/admin-module.md`, `wiki/ui-components.md` (`UserAvatar`, `NewsCarousel`).
- `CLAUDE.md`: thêm env `EXAM_FEE` và thư mục `backend/uploads/`.
- `wiki/log.md`: ghi một dòng cho mỗi phase.
- `wiki/auth-flow.md`: response login dùng key `avatarUrl`, response entity dùng key `avatar`. Sửa `spec/02-avatar.md` cho khớp.
- `backend/schema.sql`: dump lại (pg_dump) sau khi chạy hết migration, để bootstrap DB mới có đủ bảng/cột.
