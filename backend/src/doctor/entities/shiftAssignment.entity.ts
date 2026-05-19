import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { DoctorEntity } from "./doctor.entity";
import { ShiftEntity } from "./shift.entity";

@Entity('shiftAssignment')
export class ShiftAssignmentEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => DoctorEntity,(doctor) => doctor.shiftAssignments)
    doctor: DoctorEntity;

    @ManyToOne(() => ShiftEntity, (shift) => shift.shiftAssignments)
    shift: ShiftEntity;

    @Column()
    type: string;

    @Column({type: 'timestamp'})
    startTime: Date;

    @Column({type: 'timestamp'})
    endTime: Date;

    @Column()
    status: 'ACTIVE' | 'CANCELED' | 'REPLACED';

    @Column()
    duration: number;

}