import { timeStamp } from "console";
import { AppointmentEntity } from "src/patient/entities/appointment.entity";
import { Column, Entity, JoinTable, ManyToMany, ManyToOne, OneToMany, PrimaryGeneratedColumn } from "typeorm";
import { ShiftDTO } from "../dto/shift.dto";
import { ShiftEntity } from "./shift.entity";

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

    @OneToMany(() => AppointmentEntity, (appointments) => appointments.doctor)
    appointments: AppointmentEntity[];

    // làm cái của shift
    @ManyToMany(() => ShiftEntity, (shift) => shift.doctors)
    @JoinTable()
    shifts: ShiftEntity[];
}