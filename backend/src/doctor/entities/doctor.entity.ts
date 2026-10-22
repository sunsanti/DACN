import { AppointmentEntity } from "../../patient/entities/appointment.entity";
import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from "typeorm";
import { ShiftAssignmentEntity } from "./shiftAssignment.entity";

@Entity('doctor')
export class DoctorEntity {

    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    name: string;

    @Column()
    age: number;

    @Column({type: 'timestamp'})
    dateOfBirth: Date;

    @Column()
    gender: string;

    @Column()
    phone: string

    @Column()
    address: string;

    @Column()
    email: string;

    @Column({ default: '' })
    avatar: string; // /uploads/avatars/<uuid>.jpg, '' = chưa có ảnh

    @OneToMany(() => AppointmentEntity, (appointments) => appointments.doctor)
    appointments: AppointmentEntity[];

    @OneToMany(() => ShiftAssignmentEntity, (sa) => sa.doctor)
    shiftAssignments: ShiftAssignmentEntity[];
}