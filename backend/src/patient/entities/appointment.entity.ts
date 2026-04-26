import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { PatientEntity } from "./patient.entity";

@Entity('appointment')
export class AppointmentEntity {

    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    apTime: Date;

    @Column({ type: 'timestamp', nullable: true })
    confirmDate: Date;

    @Column()
    address: string;

    @Column({ type: 'text', nullable: true })
    note: string;

    @Column()
    confirmCondition: number;

    @Column()
    doctor: string;

    @ManyToOne(() => PatientEntity, (patient) => patient.appointments)
    patient: PatientEntity;

}