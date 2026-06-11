import "reflect-metadata";
import * as dotenv from "dotenv";
import { DataSource } from "typeorm";
import { DoctorEntity } from "./doctor/entities/doctor.entity";
import { ShiftEntity } from "./doctor/entities/shift.entity";
import { ShiftAssignmentEntity } from "./doctor/entities/shiftAssignment.entity";
import { AppointmentEntity } from "../src/patient/entities/appointment.entity";
import { PatientEntity } from "./patient/entities/patient.entity";
import { AccountEntity } from "./auth/entities/account.entity";
import { MedicalReportEntity } from "./patient/entities/medical_report.entity";

dotenv.config(); // load backend/.env for the TypeORM CLI (migrations)

export const AppDataSource = new DataSource({
    type: "postgres",
    host: process.env.DB_HOST ?? "localhost",
    port: Number(process.env.DB_PORT ?? "5432"),
    username: process.env.DB_USER ?? "postgres",
    password: process.env.DB_PASSWORD ?? "123456",
    database: process.env.DB_NAME ?? "dacn_db",
    entities: [
        DoctorEntity,
        ShiftEntity,
        ShiftAssignmentEntity,
        AppointmentEntity,
        PatientEntity,
        AccountEntity,
        MedicalReportEntity
    ],
    migrations: ["src/migrations/*.ts"],
    synchronize: false
});