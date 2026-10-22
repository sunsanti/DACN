import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from "typeorm";
import { AppointmentEntity } from "./appointment.entity";
import { Appointment } from "../dto/appointment.dto";

@Entity('patient')
export class PatientEntity {

    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    name: string;

    @Column()
    gender: string;

    @Column()
    age: number;

    @Column()
    birthDate: Date;

    @Column()
    email: string;

    @Column()
    phone: string;

    @Column()
    address: string;

    @Column()
    createAt: Date;

    @Column()
    avatar: string;

    // CCCD (12 số). select:false → không bao giờ lộ qua relation; chỉ /patient/me lấy riêng.
    // NULL = bệnh nhân cũ chưa có CCCD (không có BHYT).
    @Column({ type: 'varchar', length: 12, unique: true, nullable: true, select: false })
    cccd: string | null;

    @OneToMany(() => AppointmentEntity, (appointment) => appointment.patient)
    appointments: AppointmentEntity[];
    

}