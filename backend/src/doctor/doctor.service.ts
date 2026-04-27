import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { IDoctorService } from "./interfaces/doctor_service.interface";

// Import Entity thật thay vì interface
import { Shift } from "./entities/shift.entity";
import { Appointment } from "../patient/entities/appointment.entity"; // Lấy từ thư mục patient

@Injectable()
export class DoctorService implements IDoctorService {
    constructor(
        @InjectRepository(Shift)
        private readonly shiftRepo: Repository<Shift>,

        // Tiêm AppointmentRepo vào vì Bác sĩ cần quản lý lịch hẹn
        @InjectRepository(Appointment)
        private readonly appointmentRepo: Repository<Appointment>,
    ) { }

    // Lấy danh sách lịch hẹn CHƯA duyệt
    async listUnacceptedAppointment(): Promise<Appointment[]> {
        return await this.appointmentRepo.find({
            where: { confirmCondition: 0 }
        });
    }

    // Lấy danh sách lịch hẹn ĐÃ duyệt
    async listAcceptedAppointment(): Promise<Appointment[]> {
        return await this.appointmentRepo.find({
            where: { confirmCondition: 1 }
        });
    }

    // Thêm ca trực
    async addWorkingTime(shiftData: Partial<Shift>): Promise<Shift[]> {
        // Tạm thời lưu ca trực mới xuống DB dựa trên logic của Quý
        // Việc tính toán tổng giờ có thể thực hiện trên client hoặc tính tổng từ DB sau
        const newShift = this.shiftRepo.create(shiftData);
        await this.shiftRepo.save(newShift);

        // Trả về danh sách ca trực hiện tại
        return await this.shiftRepo.find();
    }

    // Hủy ca trực khẩn cấp
    async cancelShift(shiftId: number): Promise<void> {
        const now = new Date();
        const hour = now.getHours();
        const minute = now.getMinutes();

        // Giữ lại logic nháp của Quý
        // let shift: number = 1;
        // let hourLeft = (shift === 1) ? 12 - (hour + minute/60) : 8.5 - (hour + minute/60);
        // const hourWorked = hour + minute/60;

        // Hành động thật với DB: Đánh dấu ca trực là có sự cố (emergency = 1)
        const result = await this.shiftRepo.update(shiftId, { emergency: 1 });
        if (result.affected === 0) {
            throw new NotFoundException(`Không tìm thấy ca trực ID ${shiftId}`);
        }
    }

    // Đặt lại lịch hẹn
    async reAppointment(appointmentId: number): Promise<Appointment> {
        let newAppTime = new Date(); // Thời gian mới do Quý truyền vào sau
        let confirmDate = new Date();

        // Cập nhật xuống DB
        await this.appointmentRepo.update(appointmentId, {
            apTime: newAppTime,
            confirmDate: confirmDate,
            note: "Đã dời lịch hẹn", // newNote
        });

        const updated = await this.appointmentRepo.findOne({ where: { id: appointmentId } });
        if (!updated) throw new NotFoundException('Không tìm thấy lịch hẹn');
        return updated;
    }

    // Xác nhận lịch hẹn
    async confirmAppointment(appointmentId: number): Promise<Appointment> {
        // Cập nhật condition = 1 xuống DB
        await this.appointmentRepo.update(appointmentId, {
            confirmCondition: 1,
            confirmDate: new Date(),
            note: "Đã xác nhận thành công"
        });

        const updated = await this.appointmentRepo.findOne({ where: { id: appointmentId } });
        if (!updated) throw new NotFoundException('Không tìm thấy lịch hẹn');
        return updated;
    }
}