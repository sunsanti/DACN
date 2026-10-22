import { Column, CreateDateColumn, Entity, ManyToOne, OneToMany, PrimaryGeneratedColumn } from "typeorm";
import { PatientEntity } from "./patient.entity";
import { DoctorEntity } from "../../doctor/entities/doctor.entity";
import { AppointmentItemEntity } from "./appointment_item.entity";

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

    // Hoá đơn (snapshot lúc bác sĩ hoàn thành khám). NULL = chưa có hoá đơn.
    @Column({ type: 'int', nullable: true })
    examFee: number | null;

    @Column({ type: 'int', nullable: true })
    total: number | null;

    @Column({ type: 'real', nullable: true })
    insuranceRate: number | null; // 0 / 0.8 / 0.95 / 1

    @Column({ type: 'int', nullable: true })
    insuranceCovered: number | null;

    @Column({ type: 'int', nullable: true })
    payable: number | null;

    @Column({ type: 'boolean', nullable: true })
    examFeeCovered: boolean | null; // phí khám có được BHYT trả (snapshot)

    @Column({ type: 'varchar', length: 15, nullable: true })
    insuranceCardNumber: string | null; // mã thẻ BHYT đã dùng (snapshot)

    // Thanh toán: unpaid → pending (bệnh nhân chọn cash/qr) → paid (webhook SePay / admin)
    @Column({ type: 'varchar', nullable: true })
    paymentMethod: 'cash' | 'qr' | null;

    @Column({ type: 'varchar', default: 'unpaid' })
    paymentStatus: 'unpaid' | 'pending' | 'paid';

    @Column({ type: 'timestamp', nullable: true })
    paidAt: Date | null;

    @Column({ type: 'int', nullable: true })
    paidBy: number | null; // account admin xác nhận; null = webhook / tự động

    @OneToMany(() => AppointmentItemEntity, (i) => i.appointment)
    items: AppointmentItemEntity[];

    @ManyToOne(() => PatientEntity, (patient) => patient.appointments)
    patient: PatientEntity;

    @ManyToOne(() => DoctorEntity, (doctor) => doctor.appointments)
    doctor: DoctorEntity;

}