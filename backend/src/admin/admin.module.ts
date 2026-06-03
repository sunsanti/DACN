import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { AdminController } from "./admin.controller";
import { AdminService } from "./admin.service";
import { DoctorEntity } from "../doctor/entities/doctor.entity";
import { ShiftAssignmentEntity } from "../doctor/entities/shiftAssignment.entity";

@Module({
    imports: [TypeOrmModule.forFeature([DoctorEntity, ShiftAssignmentEntity])],
    controllers: [AdminController],
    providers: [AdminService],
})
export class AdminModule {}
