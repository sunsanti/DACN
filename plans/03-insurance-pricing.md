# Phase 3: BHYT + bảng giá bệnh + hoá đơn khám

Spec: `spec/03-insurance.md` **đã được sửa theo Q1/Q2** (xem `plans/README.md`). Phụ thuộc: phase 1.

## Luồng nghiệp vụ (đã chốt)
1. Admin lập **bảng giá bệnh** (tên bệnh/dịch vụ + giá).
2. Bệnh nhân khai thẻ BHYT (tuỳ chọn) khi đăng ký hoặc trong hồ sơ.
3. Đặt lịch, xác nhận, khám diễn ra như hiện tại, **chưa có tiền**.
4. Bác sĩ bấm "Hoàn thành" (gửi chẩn đoán) thì **bắt buộc chọn ít nhất một bệnh/dịch vụ, chọn được nhiều** (D1, D3). Server tính:
   ```
   total   = EXAM_FEE + sum(price của các bệnh đã chọn)
   rate    = thẻ còn hạn vào ngày apTime ? mức hưởng (1 / 0.95 / 0.8) : 0
   covered = round(total * rate)
   payable = total - covered
   ```
   và lưu **snapshot** (tổng tiền vào appointment, từng bệnh vào `appointment_item`). Sau đó admin đổi giá hay bệnh nhân đổi thẻ thì hoá đơn cũ vẫn giữ nguyên.
5. Bệnh nhân mở lịch đã khám thì thấy: phí khám, **từng bệnh + giá**, BHYT trừ (x%), còn phải trả.

Mức hưởng lấy theo ký tự thứ 3 của mã thẻ: `1,2,5` = 100%, `3` = 95%, `4` = 80%. Không xét tuyến (Q2).

## Backend

### B3.1 Logic thuần (làm trước, test trước): `backend/src/billing/billing.util.ts`
- `CARD_REGEX = /^[A-Z]{2}[1-5]\d{12}$/`
- `rateFromCard(number: string): number`
- `cardStatus(card | null, apDate): 'none' | 'valid' | 'expired' | 'not_yet_valid'` (so sánh theo **ngày**, có tính `validTo`).
- `calcBill(examFee, itemPrices: number[], card | null, apDate) => { examFee, total, insuranceRate, insuranceCovered, payable }`
- `billing.util.spec.ts`: không có thẻ; hết hạn; chưa tới ngày hiệu lực; khám đúng ngày `validTo` vẫn được hưởng; mức 1/3/4; làm tròn (ví dụ total 155.555 × 0.95); **nhiều bệnh** (cộng đúng tổng); bệnh có giá 0.

### B3.2 Migration `AddInsuranceAndPricing`
- `patient`: `insuranceNumber varchar(15) NULL`, `insuranceValidFrom date NULL`, `insuranceValidTo date NULL`.
- `disease` (mới): `id serial`, `name varchar(200) UNIQUE NOT NULL`, `price int NOT NULL CHECK (price >= 0)`, `active boolean NOT NULL DEFAULT true`.
- `appointment` (tổng hoá đơn): `examFee int NULL`, `total int NULL`, `insuranceRate real NULL`, `insuranceCovered int NULL`, `payable int NULL`. Để NULL nghĩa là "chưa có hoá đơn" (lịch cũ và lịch chưa khám), rõ hơn dùng 0.
- `appointment_item` (mới, từng bệnh trong hoá đơn): `id serial`, `appointmentId int NOT NULL FK → appointment ON DELETE CASCADE`, `name varchar(200) NOT NULL`, `price int NOT NULL`.
- `appointment_item` lưu `name` + `price` (text/số) chứ **không** FK tới disease, để admin sửa/tắt bệnh không ảnh hưởng hoá đơn cũ.
- Entity: thêm cột vào `PatientEntity`, `AppointmentEntity` (+ `@OneToMany(() => AppointmentItemEntity, i => i.appointment) items`). Tạo `DiseaseEntity`, `AppointmentItemEntity` và thêm cả hai vào `data-source.ts`.
- Chạy `npm run typeorm migration:run`.
- `reset-db.ts`: thêm `disease` vào câu TRUNCATE (`appointment_item` tự bị truncate theo CASCADE của `appointment`).

### B3.3 Module `backend/src/disease/`
- `GET /diseases`: `@Roles('admin','doctor')`. Doctor chỉ thấy `active = true`, admin thấy tất cả.
- `POST /diseases`, `PATCH /diseases/:id` (`name?`, `price?`, `active?`): `@Roles('admin')`. DTO dùng `@IsString() @IsNotEmpty()`, `@IsInt() @Min(0)`. Tên trùng thì trả 409.
- **Không có DELETE**, chỉ tắt bằng `active=false` (D2).
- Import vào `app.module.ts`. Export `TypeOrmModule` để `DoctorModule` dùng repo.

### B3.4 Thẻ BHYT của bệnh nhân
- DTO dùng chung `InsuranceDTO`: `insuranceNumber` (`@Transform` trim + uppercase + bỏ khoảng trắng, `@Matches(CARD_REGEX)`), `insuranceValidFrom`, `insuranceValidTo` (`@IsDateString()`). Cả 3 cùng có hoặc cùng không (kiểm tra trong service). `validTo >= validFrom`, sai thì 400.
- `RegisterDTO`: 3 field tuỳ chọn (multipart nên đều là string, cần `@IsOptional`).
- `PATCH /patient/me/insurance` (`@Roles('patient')`, lấy `patientId` từ JWT): body là `InsuranceDTO` hoặc `{ insuranceNumber: null, … }` để xoá thẻ.
- `GET /patient/me`: entity đã có các cột. Thêm `insuranceRate` và `insuranceStatus` (tính bằng `cardStatus(card, today)`).

### B3.5 Bác sĩ gửi chẩn đoán kèm danh sách bệnh
- `dto/complete.dto.ts`: `diseaseIds: number[]` với `@IsArray() @ArrayMinSize(1) @ArrayUnique() @IsInt({ each: true })`.
- `doctor.controller.ts:90` `completeAppointment` nhận `@Body() dto: CompleteDTO`.
- `doctor.service.completeAppointment(doctorId, id, diseaseIds)`:
  1. `assertOwns` (đã có), chỉ cho complete khi `confirmCondition === 0` và chưa huỷ.
  2. `diseaseRepo.find({ where: { id: In(diseaseIds), active: true } })`. Số bản ghi tìm được khác `diseaseIds.length` thì 400 (có id không tồn tại hoặc đã tắt).
  3. `examFee = Number(config.get('EXAM_FEE') ?? 150000)`, theo pattern `admin.service.ts:27`.
  4. `calcBill(examFee, diseases.map(d => d.price), card, appt.apTime)`.
  5. Ghi trong **một transaction** (`dataSource.transaction`): `update` appointment (`confirmCondition: 2` + 5 cột tổng) và `insert` các dòng `appointment_item`. Lỗi giữa chừng thì không để lại hoá đơn nửa vời.
- Chi tiết appointment ở cả hai phía: thêm `items` vào `relations` của truy vấn chi tiết.

### B3.6 Env
- `EXAM_FEE` trong `backend/.env` (dev mặc định 150000). Thêm vào phần env của `CLAUDE.md`.

## Frontend

### F3.1 Model
- `appointment.dart`: thêm `examFee`, `total`, `insuranceRate`, `insuranceCovered`, `payable` (nullable) và `items: List<BillItem>` (`name`, `price`, rỗng nếu chưa có).
- `patient.dart`: thêm 3 field thẻ, `insuranceRate`, `insuranceStatus`.
- `models/disease.dart` (mới).
- Hàm `formatVnd(int)` trong `core/ui.dart`: tự chèn dấu `.` ngăn cách hàng nghìn (không thêm `intl` nếu chưa có trong deps trực tiếp).

### F3.2 Bệnh nhân
- `register_screen.dart`: `ExpansionTile` "Bảo hiểm y tế (không bắt buộc)" gồm mã thẻ và 2 nút chọn ngày. Nhập đủ mã hợp lệ thì hiện "Mức hưởng: 80%" (dùng regex và bảng mức giống backend).
- `profile_screen.dart`: hiện thẻ + badge (Còn hạn/Hết hạn/Chưa khai). Có nút sửa/xoá gọi `PATCH /patient/me/insurance`.
- `appointment_detail_screen.dart`: khi `payable != null` thì hiện card "Chi phí khám", mỗi bệnh một dòng:
  ```
  Phí khám                150.000 đ
  Viêm da                  50.000 đ
  Xét nghiệm máu          100.000 đ
  ─────────────────────────────────
  Tổng                    300.000 đ
  BHYT chi trả (80%)     −240.000 đ
  Bệnh nhân trả            60.000 đ   (đậm)
  ```
  `insuranceRate == 0` thì ghi "Không áp dụng BHYT".
- Widget card này dùng chung cho cả màn bệnh nhân và bác sĩ (`BillCard` trong `core/ui.dart`).

### F3.3 Bác sĩ
- `doctor_appointment_detail_screen.dart` `_complete()`: mở dialog "Chọn bệnh/dịch vụ" gồm danh sách `CheckboxListTile` lấy từ `GET /diseases`, mỗi mục hiện tên + giá. Đáy dialog hiện **tạm tính** (phí khám + tổng các mục đã chọn, chưa trừ BHYT). Nút "Xác nhận" chỉ bật khi chọn ≥ 1 mục. Bấm xác nhận thì gửi `complete(id, diseaseIds)`. Sau khi complete thì hiện `BillCard`.
  - Danh sách dài thì thêm ô tìm kiếm lọc theo tên ở đầu dialog (lọc phía client).
- `doctor_service.complete(id, List<int> diseaseIds)` gửi body `{diseaseIds}`. `providers/doctor_provider.dart` sửa chữ ký theo.
- Phí khám dùng cho phần tạm tính: `GET /diseases` trả kèm `examFee`, tức response là `{ examFee, items: [...] }` (hoặc giữ mảng và thêm `GET /diseases/exam-fee`. Chọn cách đầu cho gọn).

### F3.4 Admin
- Mục "Bảng giá bệnh" trong `admin_home_screen.dart`: danh sách (tên, giá, switch active). FAB "+" mở dialog thêm, bấm vào dòng thì sửa. State để trong `AdminProvider`.

## Kiểm tra
- [ ] `npx jest src/billing` pass đủ các case ở B3.1.
- [ ] Smoke script (`backend/test/api-smoke.mjs`):
  - Admin tạo "Viêm da" 50.000 và "Xét nghiệm máu" 100.000. Patient đăng ký với thẻ `DN4…` (mức 80%) còn hạn. Đặt lịch, doctor confirm, doctor complete với `diseaseIds: [viêm da, xét nghiệm]`: kết quả `examFee=150000`, `total=300000`, `insuranceCovered=240000`, `payable=60000`, `items` có đúng 2 dòng.
  - Complete với 1 bệnh (50.000) thì `total=200000`, `covered=160000`, `payable=40000`.
  - Thẻ có `validTo` trước `apTime` thì `insuranceCovered=0` và `payable=total`.
  - `diseaseIds` rỗng, trùng id, có id không tồn tại, hoặc có bệnh đã tắt thì 400 và **không** có dòng `appointment_item` nào được ghi. Doctor khác complete lịch này thì 403/404 (`assertOwns`).
  - Admin đổi giá bệnh sau khi complete thì hoá đơn và `items` của lịch cũ không đổi.
  - Mã thẻ `AB6…` hoặc sai độ dài thì 400. `validTo < validFrom` thì 400. Patient gọi `POST /diseases` thì 403.
  - Complete lịch đang chờ (`confirmCondition=1`) hoặc đã huỷ thì 400.
  - Admin tắt một bệnh thì doctor `GET /diseases` không còn thấy bệnh đó, admin vẫn thấy.
- [ ] Tay: luồng đầy đủ trên app (admin lập giá, bệnh nhân khai thẻ, đặt lịch, bác sĩ hoàn thành và chọn nhiều bệnh, bệnh nhân thấy hoá đơn từng dòng).
- [ ] `npm run lint`, `npm test`, `npm run test:e2e`, `flutter analyze` sạch.

## Sau phase này
- Sửa `spec/03-insurance.md` cho khớp luồng ở trên. Đánh dấu Q1–Q3 đã chốt trong `spec/README.md`.
- Cập nhật wiki theo checklist ở `plans/README.md` (thêm bảng `appointment_item`).
