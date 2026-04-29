import { Column, Entity, ManyToMany, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { DoctorEntity } from "./doctor.entity";

@Entity('shift')
export class ShiftEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    type: 'morning' | 'afternoon';

    @Column({type: 'timestamp'})
    startTime: Date;

    @Column({ type: 'timestamp'})
    endTime: Date;

    @Column()
    emergency: number;

    @ManyToMany(() => DoctorEntity, (doctor) => doctor.shifts)
    doctors: DoctorEntity[];
}