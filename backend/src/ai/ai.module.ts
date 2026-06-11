import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { AiController } from "./ai.controller";
import { AiService } from "./ai.service";
import { MedicalReportEntity } from "../patient/entities/medical_report.entity";
import { AppointmentEntity } from "../patient/entities/appointment.entity";

@Module({
    imports: [TypeOrmModule.forFeature([MedicalReportEntity, AppointmentEntity])],
    controllers: [AiController],
    providers: [AiService],
})
export class AiModule {}
