import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { IPatientService } from "./interfaces/patient_service.interface";
import { Patient } from "./entities/patient.entity"; // Dùng Entity mới tạo
import { Appointment } from "./entities/appointment.entity"; // Dùng Entity mới tạo
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";

@Injectable()
export class PatientService implements IPatientService {
    constructor(
        @InjectRepository(Patient)
        private readonly patientRepo: Repository<Patient>,

        @InjectRepository(Appointment)
        private readonly appointmentRepo: Repository<Appointment>,
    ) { }

    // Logic cũ: Tạo lịch hẹn
    async setAppointment(dto: CreateAppoinmentDTO): Promise<Appointment> {
        // Giữ lại logic xử lý thời gian của Quý để dùng nếu cần
        // let timeInput = '26-05-2026'; 
        // const [day, month, year] = timeInput.split('-');
        // const date = new Date(`${year}-${month}-${day}`);

        // THAY THẾ: Lưu dữ liệu thật từ DTO vào Database
        const newAppointment = this.appointmentRepo.create({
            ...dto,
            confirmCondition: 1, // Giữ logic cũ của Quý là mặc định bằng 1
            // apTime: date, // Có thể dùng biến date đã xử lý ở trên
        });

        return await this.appointmentRepo.save(newAppointment);
    }

    // Logic cũ: Xóa lịch hẹn
    async deleteAppointment(id: number): Promise<{ message: string }> {
        const result = await this.appointmentRepo.delete(id);
        if (result.affected === 0) {
            throw new NotFoundException(`Không tìm thấy lịch hẹn ID ${id}`);
        }
        return { message: `Delete ${id} thành công từ Database` };
    }

    // Logic cũ: Sửa lịch hẹn
    async editAppointment(appointmentId: number): Promise<Appointment> {
        // Thay vì return object fix cứng, ta tìm trong DB và update
        // Ở đây mình ví dụ cập nhật địa chỉ theo logic cũ của Quý
        await this.appointmentRepo.update(appointmentId, {
            address: 'dia chi bac si (đã cập nhật)',
            doctor: 'bac si Quy'
        });

        const updated = await this.appointmentRepo.findOne({ where: { id: appointmentId } });
        if (!updated) throw new NotFoundException('Không tìm thấy lịch hẹn');
        return updated;
    }

    // Logic cũ: Lấy danh sách (Quý có note: "fix this function by finding with patientId")
    async listAppointment(patientId: number): Promise<Appointment[]> {
        // ĐÃ FIX: Tìm đúng danh sách lịch hẹn của patientId này trong Database
        return await this.appointmentRepo.find({
            where: { patientId: patientId }
        });
    }
}