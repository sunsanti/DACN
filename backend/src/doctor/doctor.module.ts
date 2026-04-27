import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm"; // Bắt buộc thêm dòng này
import { DoctorController } from "./doctor.controller";
import { DoctorService } from "./doctor.service";
import { Doctor } from "./entities/doctor.entity"; // Kéo bảng Doctor vào
import { Shift } from "./entities/shift.entity";   // Kéo bảng Shift vào
import { Appointment } from "../patient/entities/appointment.entity";
@Module({
    imports: [
        // Đây là "phép thuật" giúp DoctorService có quyền thao tác với Database
        TypeOrmModule.forFeature([Doctor, Shift, Appointment])
    ],
    controllers: [DoctorController],
    providers: [DoctorService],
    exports: [DoctorService] // Thêm dòng này để AuthModule sau này có thể dùng ké
})
export class DoctorModule { }