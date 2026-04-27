import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { PatientService } from "./patient.service";
import { PatientController } from "./patient.controller";
import { Patient } from "./entities/patient.entity";
import { Appointment } from "./entities/appointment.entity";

@Module({
    imports: [TypeOrmModule.forFeature([Patient, Appointment])],
    controllers: [PatientController],
    providers: [PatientService],
})
export class PatientModule {}