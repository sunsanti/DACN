import { Module } from "@nestjs/common";
import { PatientService } from "./patient.service";
import { PatientController } from "./patient.controller";
import { TypeOrmModule } from "@nestjs/typeorm";
import { PatientEntity } from "./entities/patient.entity";
import { AppointmentEntity } from "./entities/appointment.entity";
import { DoctorEntity } from "../doctor/entities/doctor.entity";
import { DoctorModule } from "../doctor/doctor.module";
import { BillingModule } from "../billing/billing.module";

@Module({
    imports: [TypeOrmModule.forFeature([PatientEntity, AppointmentEntity, DoctorEntity]), DoctorModule, BillingModule],
    controllers: [PatientController],
    providers: [PatientService],
})
export class PatientModule {}