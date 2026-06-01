import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { DoctorEntity } from '../../doctor/entities/doctor.entity';
import { PatientEntity } from './patient.entity';

@Entity('appointment')
export class AppointmentEntity {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ type: 'timestamp' })
    apTime!: Date;

    @Column({ type: 'timestamp', nullable: true })
    confirmDate!: Date | null;

    @Column({ type: 'varchar', length: 255, nullable: true })
    address!: string | null; 

    @Column({ type: 'text', nullable: true })
    note!: string | null;

    @Column({ type: 'int', default: 0 })
    confirmCondition!: number;

    @Column({ type: 'int', nullable: true })
    patientId!: number;

    // 🌟 THÊM MỐI NỐI VỚI BỆNH NHÂN
    @ManyToOne(() => PatientEntity, patient => patient.appointments)
    @JoinColumn({ name: 'patientId' })
    patient!: PatientEntity;

    @Column({ type: 'varchar', length: 255, nullable: true })
    doctorName!: string | null;

    @Column({ type: 'int', nullable: true })
    doctorId!: number;

    // 🌟 THÊM MỐI NỐI VỚI BÁC SĨ
    @ManyToOne(() => DoctorEntity, doctor => doctor.appointments)
    @JoinColumn({ name: 'doctorId' })
    doctor!: DoctorEntity;

    @Column({ type: 'varchar', length: 500, nullable: true })
    aiDiagnosticPdf!: string | null;

    @Column({ type: 'int', nullable: true })
    queueNumber!: number | null;

    @Column({ type: 'timestamp', nullable: true })
    expectedTime!: Date | null;

    @Column({ type: 'varchar', length: 50, nullable: true })
    ticketCode!: string | null;
    // 🌟 Thêm trường này vào để lưu đường dẫn file PDF chẩn đoán của AI
    
}