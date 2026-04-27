import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('shifts') // Tạo bảng 'shifts'
export class Shift {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    doctorId: number;

    @Column({ type: 'varchar' }) // Lưu 'morning' hoặc 'afternoon'
    type: 'morning' | 'afternoon';

    @Column({ type: 'timestamp' })
    startTime: Date;

    @Column({ type: 'timestamp' })
    endTime: Date;

    @Column({ default: 0 })
    emergency: number;
}