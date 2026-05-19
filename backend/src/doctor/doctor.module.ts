import { Module } from "@nestjs/common";
import { DoctorController } from "./doctor.controller";
import { DoctorService } from "./doctor.service";
import { TypeOrmModule } from "@nestjs/typeorm";
import { DoctorEntity } from "./entities/doctor.entity";
import { ShiftEntity } from "./entities/shift.entity";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { ShiftAssignmentEntity } from "./entities/shiftAssignment.entity";

@Module({
    imports: [TypeOrmModule.forFeature([DoctorEntity, ShiftEntity, AppointmentEntity, ShiftAssignmentEntity])],
    controllers: [DoctorController],
    providers: [DoctorService]
})
export class DoctorModule {}