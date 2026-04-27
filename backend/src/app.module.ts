import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm'; // BẮT BUỘC THÊM
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PatientModule } from './patient/patient.module';
import { DoctorModule } from './doctor/doctor.module';
import { AuthModule } from './auth/login/auth.module';

@Module({
  imports: [
    // BẮT BUỘC PHẢI CÓ CỤC NÀY ĐỂ KẾT NỐI DATABASE TỔNG
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: 'localhost',
      port: 5432,
      username: 'postgres',           // Tên đăng nhập pgAdmin
      password: '12345', // <<< Quý điền pass của mình
      database: 'healthcare_db',    // <<< Quý điền tên DB
      autoLoadEntities: true,         // Tự động tìm bảng User
      synchronize: true,
    }),
    PatientModule,
    DoctorModule,
    AuthModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }