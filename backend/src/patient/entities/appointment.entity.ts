import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { PatientEntity } from "./patient.entity";
import { DoctorEntity } from "src/doctor/entities/doctor.entity";

@Entity('appointment')
export class AppointmentEntity {

    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    apTime: Date;

    @Column({ type: 'timestamp', nullable: true })
    confirmDate: Date | null;

    @Column()
    address: string;

    @Column({ type: 'text', nullable: true })
    note: string | null;

    @Column()
    confirmCondition: number;

    @Column()
    doctorName: string;

    @ManyToOne(() => PatientEntity, (patient) => patient.appointments)
    patient: PatientEntity;

    @ManyToOne(() => DoctorEntity, (doctor) => doctor.appointments)
    doctor: DoctorEntity;

}