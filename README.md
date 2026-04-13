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