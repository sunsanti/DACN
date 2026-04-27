import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('patients') // Đây là tên bảng trong PostgreSQL
export class Patient {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    name: string;

    @Column()
    age: number;

    @Column({ nullable: true })
    birthDate: string;

    @Column({ unique: true }) // Email không được trùng để còn đăng nhập
    email: string;

    @Column()
    password: string; // Quý ơi, cột này cực kỳ quan trọng để login nhé!

    @Column({ nullable: true })
    phone: string;

    @Column({ nullable: true })
    address: string;

    @Column({ nullable: true })
    avatar: string;

    @CreateDateColumn() // Tự động lấy ngày giờ hiện tại khi tạo
    createAt: Date;
}