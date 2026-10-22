# 03. Bảo hiểm y tế (BHYT) + bảng giá + hoá đơn khám

> ⚠️ **Đã được thay** bởi [04-cccd-bhyt-payment.md](04-cccd-bhyt-payment.md) (đã triển khai): bỏ việc bệnh nhân tự khai thẻ, BHYT tìm theo CCCD, chỉ dịch vụ được đánh dấu mới được trừ BHYT, thêm thanh toán.

> Bản đã chốt (Q1, Q2, D1 trong `spec/README.md` và `plans/README.md`). Thay thế bản nháp cũ, trong đó giá đặt theo từng bác sĩ và tiền được tính lúc đặt lịch.

## Mục tiêu

1. Admin lập **bảng giá bệnh/dịch vụ** (tên + giá).
2. Bệnh nhân khai **thẻ BHYT** (tuỳ chọn) khi đăng ký hoặc trong hồ sơ.
3. Đặt lịch, xác nhận, khám diễn ra như cũ, **chưa có tiền**.
4. Khi **gửi chẩn đoán** (bấm "Hoàn thành"), bác sĩ **chọn một hoặc nhiều bệnh/dịch vụ**. Hệ thống tính và lưu hoá đơn:

```
Phí khám                150.000 đ   ← cố định (env EXAM_FEE)
Viêm da cơ địa           50.000 đ   ← từng bệnh đã chọn
Xét nghiệm máu          100.000 đ
Tổng                    300.000 đ
BHYT chi trả (80%)     −240.000 đ   ← nếu thẻ còn hạn vào ngày khám
Bệnh nhân trả            60.000 đ
```

5. Bệnh nhân và bác sĩ xem hoá đơn ở chi tiết lịch hẹn.

Hệ thống chỉ **tính và hiển thị**, không thu tiền.

## Quy tắc

- **Phí khám cố định**: `EXAM_FEE` (VND, mặc định 150.000), áp dụng cho mọi lượt khám.
- **Mức hưởng** lấy theo ký tự thứ 3 của mã thẻ: `1`, `2`, `5` → 100%; `3` → 95%; `4` → 80%. **Không** phân biệt đúng/trái tuyến (Q2).
- Mã thẻ hợp lệ: `^[A-Z]{2}[1-5]\d{12}$`. Server tự bỏ khoảng trắng và chuyển sang chữ in hoa.
- Thẻ có hiệu lực khi `validFrom ≤ ngày khám ≤ validTo`, so theo **ngày** ở múi giờ Asia/Ho_Chi_Minh, tính cả hai đầu.
- Công thức: `total = EXAM_FEE + Σ giá bệnh`, `covered = round(total × rate)` nếu thẻ còn hạn (ngược lại `covered = 0`), `payable = total − covered`.
- Hoá đơn là **snapshot**: sau khi đã ghi, admin đổi giá hay bệnh nhân đổi thẻ thì hoá đơn cũ vẫn giữ nguyên.
- Bác sĩ chỉ hoàn thành được lịch **đã xác nhận** và **chưa huỷ**. Phải chọn ít nhất 1 bệnh đang bật, không chọn trùng.
- Admin **không xoá** bệnh, chỉ tắt (`active=false`). Bác sĩ không thấy bệnh đã tắt.

## Dữ liệu

| Bảng | Cột |
| --- | --- |
| `patient` | `insuranceNumber` varchar(15), `insuranceValidFrom` date, `insuranceValidTo` date (cùng có hoặc cùng NULL) |
| `disease` | `id`, `name` UNIQUE, `price` int ≥ 0, `active` |
| `appointment` | `examFee`, `total`, `insuranceRate`, `insuranceCovered`, `payable` (NULL = chưa có hoá đơn) |
| `appointment_item` | `appointmentId` FK CASCADE, `name`, `price` (không FK tới `disease`) |

## API

| Route | Quyền | Mô tả |
| --- | --- | --- |
| `POST /auth/register` | public | Thêm 3 field thẻ (tuỳ chọn) |
| `PATCH /patient/me/insurance` | patient | Khai/sửa thẻ; gửi cả 3 field = `null` để xoá |
| `GET /patient/me` | patient | Thêm `insuranceRate`, `insuranceStatus` (`none`/`valid`/`expired`/`not_yet_valid`) |
| `GET /diseases` | admin, doctor | `{examFee, items}`. Bác sĩ chỉ thấy bệnh đang bật |
| `POST /diseases`, `PATCH /diseases/:id` | admin | Thêm / sửa tên, giá, bật/tắt. Tên trùng thì 409 |
| `POST /doctor/complete/:id` | doctor | `{diseaseIds: number[]}`: ghi hoá đơn + `confirmCondition=2` trong 1 transaction |
| `GET /patient/appointment/:id`, `GET /doctor/appointment/:id` | chủ lịch | Trả các cột hoá đơn + `items[]` |

## Frontend

- Đăng ký: mục "Bảo hiểm y tế (không bắt buộc)". Nhập mã hợp lệ thì hiện mức hưởng.
- Hồ sơ bệnh nhân: thẻ BHYT + badge trạng thái, nút Lưu thẻ / Xoá thẻ.
- Bác sĩ bấm "Đã khám xong" thì mở dialog chọn nhiều bệnh (có tìm kiếm và tạm tính). Nút xác nhận chỉ bật khi đã chọn ít nhất 1 bệnh.
- Chi tiết lịch (bệnh nhân + bác sĩ): `BillCard` hiện từng dòng hoá đơn.
- Admin: màn "Bảng giá bệnh" (phí khám cố định, danh sách, thêm/sửa giá, bật/tắt).

## Tiêu chí nghiệm thu (đã kiểm bằng `backend/test/api-smoke.mjs` + `billing.util.spec.ts`)

- [x] 2 bệnh (50k + 100k), thẻ 80% → total 300k, BHYT 240k, trả 60k, 2 dòng `items`.
- [x] 1 bệnh 50k, thẻ 80% → BHYT 160k, trả 40k.
- [x] Thẻ hết hạn trước ngày khám → BHYT 0.
- [x] `diseaseIds` rỗng / trùng / không tồn tại / đã tắt → 400, không ghi `items`. Bác sĩ khác → 403.
- [x] Hoàn thành lịch đang chờ hoặc đã huỷ → 400. Hoàn thành lần 2 → 400.
- [x] Đổi giá bệnh sau khi khám → hoá đơn cũ không đổi.
- [x] Mã thẻ mức 6 / sai độ dài / `validTo < validFrom` / khai thiếu ngày → 400.
- [x] Bệnh nhân gọi `POST /diseases` → 403. Bác sĩ không thấy bệnh đã tắt, admin vẫn thấy.
