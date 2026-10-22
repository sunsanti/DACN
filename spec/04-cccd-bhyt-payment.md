# 04. CCCD → BHYT tự động, dịch vụ được BHYT chi trả, thanh toán (tiền mặt / QR)

Ngày: 2026-10-04 · Trạng thái: **Đã chốt và đã triển khai** (Q1–Q6) theo `plans/04-cccd-bhyt-payment.md`. Kết quả: `screenshots/phase-5..7/`

> Spec này **thay thế phần "khai thẻ BHYT" của [03-insurance.md](03-insurance.md)**. Bệnh nhân không tự nhập mã thẻ nữa: thẻ được tìm theo CCCD. Bảng giá, hoá đơn snapshot và việc bác sĩ chọn bệnh khi hoàn thành khám vẫn giữ như spec 03.

## 1. Mục tiêu

1. Đăng ký bệnh nhân **bắt buộc nhập CCCD** (12 số).
2. Mỗi CCCD **gắn với tối đa một thẻ BHYT** trong một danh bạ BHYT có sẵn trên hệ thống.
   - Tìm thấy: hồ sơ bệnh nhân **hiện ô "Mã BHYT"** (chỉ đọc) kèm mức hưởng và hạn thẻ.
   - Không tìm thấy: **không hiện** ô này.
3. Bảng giá **đánh dấu sẵn** dịch vụ nào được BHYT chi trả. Dịch vụ không được đánh dấu thì bệnh nhân trả đủ.
4. Sau khi khám, bệnh nhân bấm **"Thanh toán"** và thấy:
   ```
   Phí khám                         150.000 đ   [BHYT]
   Viêm da cơ địa                    50.000 đ   [BHYT]
   Soi da kỹ thuật số                80.000 đ   (không BHYT)
   ─────────────────────────────────────────────
   Tổng                             280.000 đ
   BHYT chi trả (80% × 200.000 đ)  −160.000 đ
   ─────────────────────────────────────────────
   Cần thanh toán                   120.000 đ

   Phương thức:  ( ) Tiền mặt    ( ) Chuyển khoản QR
                 [ Xác nhận thanh toán ]
   ```
5. Bệnh nhân chọn **tiền mặt** hoặc **QR** để thanh toán. Admin xác nhận đã nhận tiền.

## 2. Bối cảnh và giới hạn

- Không có API công khai để tra BHYT theo CCCD (VssID/BHXH không mở cho bên thứ ba). Vì vậy hệ thống giữ một **danh bạ BHYT nội bộ** (`bhyt_registry`), đóng vai "cơ sở dữ liệu BHXH" trong phạm vi đồ án. Admin nạp dữ liệu vào danh bạ này.
- QR dùng chuẩn **VietQR** (EMVCo + NAPAS 247, chuyển khoản ngân hàng thật). **Backend tự tạo chuỗi QR**, Flutter vẽ thành ảnh (cách B, đã chốt). Tiền đi thẳng từ ngân hàng bệnh nhân sang tài khoản phòng khám, không qua hệ thống.
- Tiền về được nhận biết **tự động qua webhook SePay** (Q6, mục 9). Tiền mặt do admin xác nhận.
- App không giữ tiền và không dùng cổng thanh toán hay thẻ: tiền thật đi qua chuyển khoản ngân hàng (QR) hoặc tiền mặt tại quầy.

## 3. Quy tắc nghiệp vụ

### CCCD
- Định dạng: đúng **12 chữ số** (`^\d{12}$`).
- **Duy nhất**: một CCCD chỉ gắn với một tài khoản bệnh nhân. Trùng thì trả 409 `CCCD đã được đăng ký`.
- Sau khi đăng ký, bệnh nhân **không tự sửa** CCCD (tránh đổi sang CCCD người khác để hưởng BHYT). Muốn sửa thì nhờ admin, xem Q4.
- CCCD là dữ liệu cá nhân nhạy cảm: API chỉ trả **dạng che** (`0790******89`) cho mọi người, trừ chính chủ ở `/patient/me`. Không ghi log CCCD.

### Gắn BHYT theo CCCD
- Tra `bhyt_registry` theo `cccd`. Có bản ghi thì bệnh nhân **có BHYT**.
- Kiểm tra thêm: `birthDate` trong danh bạ phải **trùng ngày sinh** của bệnh nhân. Lệch thì coi như **không có** BHYT, để chặn trường hợp nhập nhầm hoặc dùng CCCD người khác (Q2).
- Không copy thẻ vào bảng `patient`. Mỗi lần cần thì tra danh bạ, nên admin cập nhật danh bạ (gia hạn thẻ) là có hiệu lực ngay cho các **hoá đơn sau này**.
- Mức hưởng và hạn thẻ giữ nguyên quy tắc của spec 03: ký tự thứ 3 của mã (`1,2,5` → 100%, `3` → 95%, `4` → 80%), thẻ hợp lệ khi `validFrom ≤ ngày khám ≤ validTo`.

### Dịch vụ được BHYT chi trả
- Mỗi bệnh/dịch vụ trong bảng giá có cờ **`bhytCovered`** (mặc định `true`). Admin bật/tắt cờ này.
- **Phí khám cố định** cũng có cờ riêng (env `EXAM_FEE_BHYT_COVERED`, mặc định `true`, Q1).
- Công thức (thay cho công thức trong spec 03):
  ```
  total        = phí khám + Σ giá dịch vụ
  coveredBase  = (phí khám nếu được BHYT) + Σ giá dịch vụ có bhytCovered
  rate         = thẻ hợp lệ ngày khám ? mức hưởng : 0
  covered      = round(coveredBase × rate)
  payable      = total − covered
  ```
- Mỗi dòng hoá đơn lưu snapshot cả cờ `bhytCovered`. Admin đổi cờ sau đó thì hoá đơn cũ không đổi.

### Thanh toán
- Chỉ thanh toán được lịch **đã khám xong** (`confirmCondition = 2`), **có hoá đơn**, và `payable > 0`. Nếu `payable = 0` (BHYT trả 100%), lịch tự chuyển sang `paid` ngay khi bác sĩ hoàn thành khám.
- Trạng thái `paymentStatus`:
  ```
  unpaid ──(bệnh nhân chọn cash/qr)──▶ pending ──(admin xác nhận)──▶ paid
                 ▲                        │
                 └──(bệnh nhân đổi phương thức, khi còn pending)
  ```
- **Tiền mặt**: chuyển sang `pending` và hiện hướng dẫn "Vui lòng thanh toán tại quầy, mã lịch #17".
- **QR**: chuyển sang `pending`, hiện mã VietQR **động** (mỗi lịch một mã):
  - **Cố định** (env, bệnh nhân không đổi được): mã BIN ngân hàng + số tài khoản phòng khám.
  - **Theo lịch**: số tiền = `payable`, nội dung CK = `DACN{id}` (VD `DACN17`).
  - App ngân hàng quét ra thì tự điền đủ 4 thông tin trên. Đa số app khoá ô số tiền, nhưng chuẩn không bắt buộc. Vì vậy khi xác nhận, admin **phải đối chiếu số tiền thực nhận với `payable`** và nội dung `DACN{id}`.
- Admin xác nhận `paid` (lưu `paidAt` và người xác nhận). Đã `paid` thì không đổi được nữa.

## 4. Dữ liệu (migration `CccdBhytPayment`)

| Bảng | Thay đổi |
| --- | --- |
| `patient` | **+** `cccd` varchar(12) UNIQUE. NULL được, để bệnh nhân cũ không vỡ; đăng ký mới bắt buộc. **−** bỏ `insuranceNumber`, `insuranceValidFrom`, `insuranceValidTo` (spec 03) |
| `bhyt_registry` (mới) | `id`, `cccd` varchar(12) UNIQUE, `cardNumber` varchar(15) UNIQUE, `fullName`, `birthDate` date, `validFrom` date, `validTo` date |
| `disease` | **+** `bhytCovered` boolean NOT NULL DEFAULT true |
| `appointment_item` | **+** `bhytCovered` boolean NOT NULL DEFAULT true (snapshot) |
| `appointment` | **+** `examFeeCovered` boolean, `insuranceCardNumber` varchar(15) NULL (snapshot mã thẻ đã dùng), `paymentMethod` varchar NULL (`cash`/`qr`), `paymentStatus` varchar NOT NULL DEFAULT `'unpaid'`, `paidAt` timestamp NULL, `paidBy` int NULL (account admin) |

- Data migration: bệnh nhân cũ có thẻ (spec 03) và có CCCD thì chuyển thẻ sang `bhyt_registry`. Bệnh nhân cũ không có CCCD thì bỏ thẻ. Các hoá đơn đã ghi vẫn giữ nguyên.
- `reset-db.ts`: thêm `bhyt_registry`. Seed vài bản ghi danh bạ mẫu cho demo (Q3).

## 5. API

| Route | Quyền | Thay đổi |
| --- | --- | --- |
| `POST /auth/register` | public | **+** `cccd` (bắt buộc). **−** bỏ 3 field thẻ BHYT |
| `GET /patient/me` | patient | **+** `cccd` (đầy đủ, chính chủ), **+** `insurance`: `null` nếu không có BHYT, ngược lại `{cardNumber, validFrom, validTo, rate, status}` |
| `PATCH /patient/me/insurance` | — | **Xoá** (bệnh nhân không tự khai thẻ nữa) |
| `GET /bhyt-registry?q=` | admin | Danh sách / tìm theo CCCD hoặc mã thẻ |
| `POST /bhyt-registry`, `PATCH /bhyt-registry/:id`, `DELETE /bhyt-registry/:id` | admin | Quản lý danh bạ. CCCD hoặc mã thẻ trùng thì 409. Validate định dạng như trên |
| `POST /diseases`, `PATCH /diseases/:id` | admin | **+** `bhytCovered` |
| `GET /diseases` | admin, doctor | Trả kèm `bhytCovered`, `examFeeBhytCovered` |
| `POST /doctor/complete/:id` | doctor | Tính theo công thức mới (chỉ phần có BHYT). Snapshot `bhytCovered` từng dòng + `insuranceCardNumber`. `payable = 0` thì `paymentStatus = paid` |
| `POST /patient/appointment/:id/pay` | patient (chủ lịch) | `{method: 'cash' \| 'qr'}`. Chuyển `unpaid`/`pending` → `pending`. Trả `{paymentStatus, method, payable, qr?}`, với `qr = {payload, bankName, accountNo, accountName, amount, content}` khi chọn QR. `payload` là chuỗi VietQR để app vẽ |
| `GET /admin/payments?status=pending` | admin | Danh sách lịch chờ xác nhận thanh toán |
| `POST /admin/payments/:appointmentId/confirm` | admin | `pending` → `paid`. Lưu `paidAt`, `paidBy` |

- Đi qua thanh toán, mọi lỗi trạng thái (chưa khám, đã `paid`, không có hoá đơn) đều trả 400. Lịch không thuộc bệnh nhân đang gọi thì 403 (`assertOwns` có sẵn).
- Env mới: `PAYMENT_BANK_BIN` (VD `970422` = MB Bank), `PAYMENT_BANK_NAME` (chỉ để hiển thị), `PAYMENT_ACCOUNT_NO`, `PAYMENT_ACCOUNT_NAME` (in hoa không dấu), `EXAM_FEE_BHYT_COVERED`. Thiếu env thanh toán thì `method: 'qr'` trả 503 `Chưa cấu hình tài khoản nhận`, còn tiền mặt vẫn dùng được.

### Tạo chuỗi VietQR (`backend/src/billing/vietqr.util.ts`, hàm thuần)

`buildVietQr({bin, accountNo, amount, content}) → string`. Chuỗi gồm các trường dạng `ID(2 số) + độ dài(2 số) + giá trị`, theo thứ tự:

| ID | Ý nghĩa | Giá trị |
| --- | --- | --- |
| `00` | Payload format | `01` |
| `01` | Kiểu QR | `12` (**động**, có số tiền) |
| `38` | Thông tin người nhận (NAPAS) | `00`=`A000000727` · `01`=[`00`=BIN · `01`=số TK] · `02`=`QRIBFTTA` (chuyển vào tài khoản) |
| `53` | Tiền tệ | `704` (VND) |
| `54` | Số tiền | `payable`, số nguyên, không dấu chấm |
| `58` | Quốc gia | `VN` |
| `62` | Dữ liệu thêm | `08`=nội dung CK `DACN{id}` (chỉ chữ/số ASCII, ≤ 25 ký tự) |
| `63` | CRC | 4 ký tự hex in hoa: CRC-16/CCITT-FALSE (poly `0x1021`, init `0xFFFF`) của toàn chuỗi **tính cả** `6304` |

- Không cần thư viện backend: ghép chuỗi + hàm CRC khoảng 15 dòng.
- `vietqr.util.spec.ts`: CRC của `"123456789"` = `29B1` (giá trị kiểm chuẩn của CRC-16/CCITT-FALSE); chuỗi đúng thứ tự trường và độ dài; đổi 1 ký tự thì CRC đổi; số tiền 0 hoặc âm thì throw.
- Kiểm chứng thật: quét mã sinh ra bằng app ngân hàng, thấy đúng tài khoản/số tiền/nội dung rồi chuyển thử 2.000 đ (làm tay, ghi vào tiêu chí nghiệm thu).

## 6. Frontend

### Đăng ký (`register_screen.dart`)
- **+** ô "Số CCCD" (bắt buộc, chỉ nhận số, đủ 12 ký tự).
- **−** bỏ mục "Bảo hiểm y tế (không bắt buộc)" của spec 03.

### Hồ sơ (`profile_screen.dart`)
- Hiện CCCD dạng chỉ đọc.
- `insurance != null`: hiện card **"Mã BHYT"** (chỉ đọc) gồm mã thẻ, mức hưởng, hạn thẻ và badge Còn hạn/Hết hạn.
- `insurance == null`: **không hiện** card này.
- **−** bỏ form nhập/sửa/xoá thẻ.

### Chi tiết lịch đã khám (`appointment_detail_screen.dart`)
- `BillCard`: mỗi dòng có nhãn **BHYT** nếu được chi trả. Dòng BHYT ghi rõ `80% × {coveredBase}`. Dòng cuối là "Cần thanh toán".
- Badge trạng thái thanh toán: Chưa thanh toán / Chờ xác nhận (Tiền mặt|QR) / Đã thanh toán.
- Nút **"Thanh toán"** khi `unpaid`, hoặc **"Đổi phương thức"** khi `pending`, mở màn `PaymentScreen`.

### `PaymentScreen` (mới)
- Trên cùng: bảng giá như mục 1, tái dùng `BillCard`.
- Dưới: `RadioListTile` × 2 (Tiền mặt / Chuyển khoản QR) và nút **"Xác nhận thanh toán"** (disabled khi chưa chọn).
- Chọn QR thì vẽ mã bằng `QrImageView(data: qr.payload, version: QrVersions.auto, size: 240)` (package **`qr_flutter`**, dependency mới duy nhất), nền trắng. Bên dưới hiện tên ngân hàng, số tài khoản, tên người nhận, số tiền, nội dung CK (có nút copy), và dòng "Mở app ngân hàng → Quét QR. Sau khi chuyển khoản, nhân viên sẽ xác nhận".
- Chọn tiền mặt thì hiện "Vui lòng thanh toán tại quầy, đọc mã lịch #17".

### Admin
- **"Danh bạ BHYT"** (mới): danh sách, tìm theo CCCD/mã thẻ, thêm/sửa/xoá.
- **"Bảng giá bệnh"**: thêm switch "BHYT chi trả" cho mỗi dịch vụ. Dòng phí khám hiện trạng thái BHYT (lấy từ env).
- **"Thanh toán chờ xác nhận"** (mới): danh sách lịch `pending` (bệnh nhân, số tiền, phương thức, thời gian), nút "Đã nhận tiền".

### Bác sĩ
- Dialog chọn bệnh (spec 03) hiện thêm nhãn **BHYT** cạnh dịch vụ được chi trả. Phần tạm tính giữ nguyên (chưa trừ BHYT).

## 7. Tiêu chí nghiệm thu

**Đăng ký và hồ sơ**
- [ ] Đăng ký thiếu CCCD, hoặc CCCD không đủ 12 số / có chữ → 400.
- [ ] Đăng ký CCCD đã có tài khoản → 409.
- [ ] CCCD có trong danh bạ và trùng ngày sinh → `/patient/me` có `insurance`, app hiện ô "Mã BHYT".
- [ ] CCCD không có trong danh bạ, hoặc ngày sinh lệch → `insurance = null`, app **không** hiện ô.
- [ ] Bệnh nhân khác / bác sĩ không bao giờ thấy CCCD đầy đủ.

**Tính tiền**
- [ ] Phí khám 150k [BHYT] + Viêm da 50k [BHYT] + Soi da 80k [không BHYT], thẻ 80% → total 280k, BHYT 160k, cần trả 120k.
- [ ] Toàn dịch vụ không BHYT, chỉ phí khám có BHYT, thẻ 100% → chỉ trừ phí khám.
- [ ] Không có BHYT hoặc thẻ hết hạn ngày khám → BHYT 0.
- [ ] Admin đổi `bhytCovered` sau khi khám → hoá đơn cũ không đổi.
- [ ] Thẻ 100% và mọi dòng đều BHYT → `payable = 0`, tự `paid`, không hiện nút Thanh toán.

**Thanh toán**
- [ ] Chọn tiền mặt → `pending`, phương thức `cash`. Đổi sang QR khi còn `pending` → OK, có `qr.payload` chứa đúng BIN, số TK, số tiền `payable` và nội dung `DACN{id}`, CRC hợp lệ.
- [ ] (Tay) Quét mã trên app bằng app ngân hàng thật: tự điền đúng tài khoản, số tiền, nội dung. Chuyển thử 2.000 đ thành công.
- [ ] Chưa cấu hình env ngân hàng → chọn QR trả 503, tiền mặt vẫn OK.
- [ ] Thanh toán lịch chưa khám / đã `paid` / của người khác → 400 / 400 / 403.
- [ ] Admin xác nhận → `paid`, có `paidAt`. Xác nhận lại → 400. Bệnh nhân gọi API admin → 403.
- [ ] `billing.util.spec.ts` bổ sung case: dòng không BHYT, phí khám không BHYT, `coveredBase = 0`.
- [ ] `vietqr.util.spec.ts` pass (CRC chuẩn, thứ tự trường, số tiền không hợp lệ).

## 8. Ngoài phạm vi
- Tra BHYT thật với BHXH, đối soát ngân hàng tự động (webhook/Casso/SePay), hoàn tiền, xuất hoá đơn VAT, thanh toán từng phần.

## 9. Câu hỏi đã chốt (ghi đè các mục phía trên nếu mâu thuẫn)

- [x] **Q1:** Phí khám cố định **có** được BHYT chi trả.
- [x] **Q2:** **Có** kiểm tra ngày sinh trùng với danh bạ trước khi gắn BHYT.
- [x] **Q3:** Danh bạ BHYT là **dữ liệu có sẵn** (seed trong migration), giống cơ sở dữ liệu BHXH. **Admin không có quyền đăng ký/sửa BHYT**: bỏ toàn bộ API `/bhyt-registry` và màn "Danh bạ BHYT". Bệnh nhân hoặc có sẵn trong danh bạ, hoặc không.
- [x] **Q4:** Bệnh nhân cũ chưa có CCCD thì **để trống** (không có BHYT). Không làm màn admin sửa CCCD.
- [x] **Q5:** **Cách B**: backend tự tạo chuỗi VietQR, Flutter vẽ bằng `qr_flutter`.
- [x] **Q6:** **Tự động** nhận biết tiền về qua **webhook SePay**:
  - SePay gọi `POST /payments/sepay-webhook` (header `Authorization: Apikey <SEPAY_API_KEY>`, body có `id`, `transferType`, `transferAmount`, `content`, …). Server trả `{"success": true}`. SePay thử lại tối đa 7 lần nên chống ghi trùng theo `id`.
  - Nội dung chứa `DACN{id}` và số tiền **bằng** `payable` → lịch chuyển `paid` và **gửi thông báo cho admin**: "Đã nhận {số tiền} từ bệnh nhân {tên}, khám bởi BS {tên bác sĩ}, lịch #{id}, nội dung CK …".
  - Số tiền lệch, hoặc không tìm thấy lịch → **không** chuyển `paid`, gửi thông báo cảnh báo cho admin để xử lý tay.
  - Admin vẫn có nút **"Đã nhận tiền"** cho **tiền mặt** (và để xử lý tay các giao dịch lệch).
  - Bệnh nhân đang ở màn thanh toán: app hỏi lại trạng thái mỗi 3 giây. Khi `paid` thì hiện **Lottie dấu tích** và **pháo giấy / băng rôn rơi xuống** (package `lottie` + `confetti`).
  - Chạy thật cần: tài khoản SePay liên kết ngân hàng nhận, cấu hình URL webhook public (khi dev dùng ngrok), đặt `SEPAY_API_KEY`. Khi dev/test, smoke test giả lập lời gọi webhook.
