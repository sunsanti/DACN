src/
├── app.module.ts
├── main.ts
│
├── common/                     # Dùng chung toàn app
│   ├── decorators/
│   ├── guards/
│   ├── filters/
│   └── interceptors/
│
├── config/                     # Cấu hình môi trường, DB...
│   └── database.config.ts
│
├── database/                   # Kết nối DB, migrations
│   └── database.module.ts
│
├── auth/                       # Login, logout, JWT
│   ├── auth.module.ts
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   └── strategies/
│       └── jwt.strategy.ts
│
├── patient/                    # Chức năng bệnh nhân
│   ├── patient.module.ts
│   ├── patient.controller.ts
│   ├── patient.service.ts
│   ├── patient.entity.ts
│   └── dto/
│       ├── create-patient.dto.ts
│       └── update-patient.dto.ts
│
└── doctor/                     # Chức năng bác sĩ
    ├── doctor.module.ts
    ├── doctor.controller.ts
    ├── doctor.service.ts
    ├── doctor.entity.ts
    └── dto/
        ├── create-doctor.dto.ts
        └── update-doctor.dto.ts

    
Other package used in this project (all install on npm library):
    - ORM
    - validator


Job cần làm:
Thái Văn Quý FE
Quân Dương :BE

FE:
- Đăng nhập:
- Đăng kí:
doctor không được đăng kí, patient có thể đăng kí, admin thì có sẵn k cần đăng kí
form đăng nhập patient thì có thể xem interface của patient.interface.ts để biết patient cần gì
có thể sẽ cập nhật thêm vì cần phải làm cccd và bảo hiểm y tế + hạn sử dụng bảo hiểm nên sẽ thay đổi sau
- Admin:
xem số giờ làm việc của bác sĩ để tính lương để trả + xem số tièn tổng cộng trong 1 tháng/ 1 tuần/ nhiều tuần
thêm tài khoản bác sĩ, thông tin bác sĩ thì ở doctor.interface.ts

trang chính bệnh nhân:
thêm cuộc hẹn,
sửa cuộc hẹn,
xoá cuộc hẹn,
tìm kiếm lịch hẹn

trang bác sĩ:
thêm lịch làm,
xác nhận lịch hẹn,
huỷ ca làm
tái khám

hiện tại rứa đã, cái nào xong thì đánh dấu tích vào cho dễ biết