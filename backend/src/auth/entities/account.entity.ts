import {
    Column,
    CreateDateColumn,
    Entity,
    JoinColumn,
    OneToOne,
    PrimaryGeneratedColumn,
} from "typeorm";
import { PatientEntity } from "../../patient/entities/patient.entity";
import { DoctorEntity } from "../../doctor/entities/doctor.entity";

export type AccountRole = "patient" | "doctor" | "admin";

@Entity("account")
export class AccountEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    email: string;

    @Column()
    passwordHash: string;

    @Column()
    role: AccountRole;

    @OneToOne(() => PatientEntity, { nullable: true, onDelete: "SET NULL" })
    @JoinColumn()
    patient: PatientEntity | null;

    @OneToOne(() => DoctorEntity, { nullable: true, onDelete: "SET NULL" })
    @JoinColumn()
    doctor: DoctorEntity | null;

    @CreateDateColumn()
    createdAt: Date;
}
