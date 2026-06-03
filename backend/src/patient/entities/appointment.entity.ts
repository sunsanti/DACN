import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { PatientEntity } from "./patient.entity";
import { DoctorEntity } from "../../doctor/entities/doctor.entity";

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
    note: string | null; // ghi chú của BỆNH NHÂN (không bị bác sĩ override)

    @Column({ type: 'text', nullable: true })
    doctorNote: string | null; // ghi chú của BÁC SĨ gửi về bệnh nhân

    @Column()
    confirmCondition: number; // 1=chờ, 0=đã xác nhận, 2=đã khám xong

    @Column({ type: 'text', nullable: true })
    cancelReason: string | null; // nếu set => lịch đã bị hủy

    @Column({ type: 'varchar', nullable: true })
    canceledBy: 'patient' | 'doctor' | null;

    @Column({ type: 'boolean', default: false })
    rescheduled: boolean; // đã dùng 1 lần đổi lịch chưa

    @Column()
    doctorName: string;

    @ManyToOne(() => PatientEntity, (patient) => patient.appointments)
    patient: PatientEntity;

    @ManyToOne(() => DoctorEntity, (doctor) => doctor.appointments)
    doctor: DoctorEntity;

}