import { Module } from "@nestjs/common";
import { PatientService } from "./patient.service";
import { PatientController } from "./patient.controller";
import { TypeOrmModule } from "@nestjs/typeorm";
import { PatientEntity } from "./entities/patient.entity";
import { AppointmentEntity } from "./entities/appointment.entity";

@Module({
    imports: [TypeOrmModule.forFeature([PatientEntity, AppointmentEntity])],
    controllers: [PatientController],
    providers: [PatientService],
})
export class PatientModule {}