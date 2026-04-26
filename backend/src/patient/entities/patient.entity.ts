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

    @OneToMany(() => AppointmentEntity, (appointment) => appointment.patient)
    appointments: AppointmentEntity[];

}