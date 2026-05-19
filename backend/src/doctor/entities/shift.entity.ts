import { Column, Entity, ManyToMany, ManyToOne, OneToMany, PrimaryGeneratedColumn } from "typeorm";
import { DoctorEntity } from "./doctor.entity";
import { ShiftAssignmentEntity } from "./shiftAssignment.entity";

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

    // @Column()
    // emergency: number;


    // @ManyToMany(() => DoctorEntity, (doctor) => doctor.shifts)
    // doctors: DoctorEntity[];

    @OneToMany(() => ShiftAssignmentEntity, (sa) => sa.shift)
    shiftAssignments: ShiftAssignmentEntity[];
    
}