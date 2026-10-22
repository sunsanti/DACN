import { Module } from "@nestjs/common";
import { DoctorController } from "./doctor.controller";
import { DoctorService } from "./doctor.service";
import { TypeOrmModule } from "@nestjs/typeorm";
import { DoctorEntity } from "./entities/doctor.entity";
import { ShiftEntity } from "./entities/shift.entity";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { ShiftAssignmentEntity } from "./entities/shiftAssignment.entity";
import { MedicalReportEntity } from "../patient/entities/medical_report.entity";
import { DiseaseModule } from "../disease/disease.module";
import { BillingModule } from "../billing/billing.module";
import { AppointmentItemEntity } from "../patient/entities/appointment_item.entity";

@Module({
    imports: [TypeOrmModule.forFeature([DoctorEntity, ShiftEntity, AppointmentEntity, ShiftAssignmentEntity, MedicalReportEntity, AppointmentItemEntity]), DiseaseModule, BillingModule],
    controllers: [DoctorController],
    providers: [DoctorService],
    exports: [DoctorService],
})
export class DoctorModule {}