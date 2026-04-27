import { timeStamp } from "console";
import { AppointmentEntity } from "src/patient/entities/appointment.entity";
import { Column, Entity, ManyToOne, OneToMany, PrimaryGeneratedColumn } from "typeorm";

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
}