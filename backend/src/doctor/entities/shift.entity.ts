import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from "typeorm";
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

    @OneToMany(() => ShiftAssignmentEntity, (sa) => sa.shift)
    shiftAssignments: ShiftAssignmentEntity[];
    
}