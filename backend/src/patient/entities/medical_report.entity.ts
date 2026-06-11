import {
    Column,
    CreateDateColumn,
    Entity,
    JoinColumn,
    ManyToOne,
    PrimaryGeneratedColumn,
} from "typeorm";
import { AppointmentEntity } from "./appointment.entity";

@Entity("medical_report")
export class MedicalReportEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => AppointmentEntity, { onDelete: "CASCADE" })
    @JoinColumn({ name: "appointmentId" })
    appointment: AppointmentEntity;

    @Column({ type: "bytea" })
    pdf: Buffer;

    @CreateDateColumn()
    createdAt: Date;
}
