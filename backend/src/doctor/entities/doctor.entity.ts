import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('doctors') // Tạo bảng 'doctors' trong Database
export class Doctor {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    name: string;

    @Column({ nullable: true })
    age: number;

    @Column({ type: 'date', nullable: true })
    dateOfBirth: Date;

    @Column({ nullable: true })
    gender: string;

    @Column({ nullable: true })
    phone: string;

    @Column({ nullable: true })
    address: string;

    @Column({ unique: true }) // Bắt buộc unique để không bị trùng tài khoản
    email: string;

    @Column()
    password: string; // <-- Cột này thêm vào để Auth/Login
}