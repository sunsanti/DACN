// Xóa bỏ import { timeStamp } from "console" bị sinh ra do ấn nhầm
import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from "typeorm";
import { AppointmentEntity } from "../../patient/entities/appointment.entity";
import { ShiftAssignmentEntity } from "./shiftAssignment.entity";
// import { ShiftDTO } from "../dto/shift.dto"; // Tạm ẩn nếu không dùng
// import { ShiftEntity } from "./shift.entity";

@Entity('doctor')
export class DoctorEntity {
    // 🌟 THÊM DẤU "!" VÀO TẤT CẢ CÁC BIẾN ĐỂ SỬA LỖI ĐỎ
    @PrimaryGeneratedColumn()
    id!: number;

    @Column()
    name!: string;

    @Column()
    age!: number;

    // 💡 Ghi chú: Theo dữ liệu bạn gửi lúc nãy, tên cột trong bảng pgAdmin là 'birthDate'. 
    // Nếu bạn muốn giữ tên biến là 'dateOfBirth' trong code, hãy map nó như dưới đây:
    @Column({ name: 'birthDate', type: 'timestamp' })
    dateOfBirth!: Date;

    @Column()
    gender!: string;

    @Column()
    phone!: string;

    @Column()
    address!: string;

    @Column()
    email!: string;

    // ==========================================
    // 🌟 THÊM 4 CỘT MỚI TẠO TỪ PGADMIN VÀO ĐÂY
    // ==========================================
    @Column({ nullable: true })
    specialty!: string;

    @Column({ default: 0 })
    experience!: number;

    @Column({ type: 'text', nullable: true })
    description!: string;

    @Column({ nullable: true })
    avatar!: string;

    // ==========================================
    // CÁC QUAN HỆ (RELATIONS)
    // ==========================================
    @OneToMany(() => AppointmentEntity, (appointments) => appointments.doctor)
    appointments!: AppointmentEntity[];

    // làm cái của shift
    // @ManyToMany(() => ShiftEntity, (shift) => shift.doctors)
    // @JoinTable()
    // shifts: ShiftEntity[];

    @OneToMany(() => ShiftAssignmentEntity, (sa) => sa.doctor)
    shiftAssignments!: ShiftAssignmentEntity[];
}