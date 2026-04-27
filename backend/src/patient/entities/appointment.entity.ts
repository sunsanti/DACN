import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('appointments')
export class Appointment {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ type: 'timestamp' })
    apTime: Date;

    @Column({ type: 'timestamp', nullable: true })
    confirmDate: Date;

    @Column()
    address: string;

    @Column({ type: 'text', nullable: true })
    note: string;

    @Column({ default: 0 }) // 0: Chờ duyệt, 1: Đã duyệt...
    confirmCondition: number;

    @Column()
    doctor: string;

    @Column()
    patientId: number;

    @Column()
    doctorId: number;
}