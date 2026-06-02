import "reflect-metadata";
import { DataSource } from "typeorm";
import { DoctorEntity } from "./doctor/entities/doctor.entity";
import { ShiftEntity } from "./doctor/entities/shift.entity";
import { ShiftAssignmentEntity } from "./doctor/entities/shiftAssignment.entity";
import { AppointmentEntity } from "../src/patient/entities/appointment.entity";
import { PatientEntity } from "./patient/entities/patient.entity";
import { AccountEntity } from "./auth/entities/account.entity";

export const AppDataSource = new DataSource({
    type: "postgres",
    host: "localhost",
    port: 5432,
    username: "postgres",
    password: "123456",
    database: "dacn_db",
    entities: [
        DoctorEntity,
        ShiftEntity,
        ShiftAssignmentEntity,
        AppointmentEntity,
        PatientEntity,
        AccountEntity
    ],
    migrations: ["src/migrations/*.ts"],
    synchronize: false
});