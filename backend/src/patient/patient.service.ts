import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { AppointmentEntity } from "./entities/appointment.entity";
import { Repository } from "typeorm";
import { PatientEntity } from "./entities/patient.entity";
import { DoctorEntity } from "../doctor/entities/doctor.entity";

// 🌟 Import thêm thư viện để xử lý File và PDF
import * as fs from 'fs';
import * as path from 'path';
const PDFDocument = require('pdfkit');

@Injectable()
export class PatientService {
    constructor(
        @InjectRepository(AppointmentEntity)
        private appointmentRepo: Repository<AppointmentEntity>,

        @InjectRepository(PatientEntity)
        private patientRepo: Repository<PatientEntity>,

        // 🌟 REPO BÁC SĨ ĐÃ ĐƯỢC INJECT
        @InjectRepository(DoctorEntity)
        private doctorRepo: Repository<DoctorEntity>
    ) {}

    // 🌟 Tạo lịch hẹn mới (Đã tích hợp AI + Xuất PDF + Trạng thái Chờ duyệt)
    async setAppointment(dto: any): Promise<AppointmentEntity> {
        // 1. Tạo ra 1 thực thể rỗng và bơm dữ liệu từ Flutter lên
        const newAppointment = this.appointmentRepo.create();
        Object.assign(newAppointment, dto);
        
        // Chốt hạ trạng thái: 0 = Chờ duyệt (Pending)
        newAppointment.confirmCondition = 0; 

        // 2. GIẢ LẬP CHẨN ĐOÁN AI (Xử lý keywords từ triệu chứng bệnh nhân)
        let aiDiagnosis = "Hệ thống ghi nhận triệu chứng bình thường. Cần bác sĩ kiểm tra lâm sàng.";
        if (dto.note && dto.note.toLowerCase().includes('ho')) {
            aiDiagnosis = "AI dự đoán: Có thể bị Viêm họng hoặc Cảm cúm. Khuyến nghị: Kiểm tra họng, đo thân nhiệt.";
        } else if (dto.note && (dto.note.toLowerCase().includes('đau bụng') || dto.note.toLowerCase().includes('dau bung'))) {
            aiDiagnosis = "AI dự đoán: Có thể bị Rối loạn tiêu hóa hoặc Viêm dạ dày. Khuyến nghị: Siêu âm ổ bụng.";
        }

        // 3. XỬ LÝ XUẤT FILE PDF
        try {
            // Tạo thư mục 'uploads/pdfs' nếu chưa có
            const pdfDir = path.join(process.cwd(), 'uploads', 'pdfs');
            if (!fs.existsSync(pdfDir)) {
                fs.mkdirSync(pdfDir, { recursive: true });
            }

            // Đặt tên file theo ID bệnh nhân và thời gian để không trùng lặp
            const fileName = `booking_${dto.patientId}_${Date.now()}.pdf`;
            const filePath = path.join(pdfDir, fileName);

            // Bắt đầu vẽ file PDF
            const doc = new PDFDocument();
            
            // Dùng Promise để đảm bảo file PDF được ghi xong hoàn toàn
            const writeStream = fs.createWriteStream(filePath);
            doc.pipe(writeStream);

            // NHÚNG FONT TIẾNG VIỆT VÀO PDF
            const fontPath = path.join(process.cwd(), 'fonts', 'arial.ttf');
            if (fs.existsSync(fontPath)) {
                doc.font(fontPath); // Bắt PDFKit sử dụng font này
            } else {
                console.log("⚠️ Không tìm thấy file font Tiếng Việt (Roboto_regular.ttf), sẽ dùng font mặc định.");
            }

            // Nội dung PDF hiển thị Tiếng Việt có dấu mượt mà
            doc.fontSize(20).text('PHÒNG KHÁM THÔNG MINH - PHIẾU ĐĂNG KÝ KHÁM', { align: 'center' });
            doc.moveDown();
            doc.fontSize(14).fillColor('black').text(`Mã bệnh nhân: ${dto.patientId || 'Chưa rõ'}`);
            doc.text(`Bác sĩ đăng ký: ${dto.doctorName || 'Chưa chọn'}`);
            doc.text(`Thời gian khám: ${dto.apTime}`);
            doc.text(`Triệu chứng của bệnh nhân: ${dto.note || 'Không có'}`);
            doc.moveDown();
            
            // In kết quả AI
            doc.fontSize(14).fillColor('blue').text('--- KẾT QUẢ CHẨN ĐOÁN SƠ BỘ TỪ AI ---');
            doc.fontSize(12).fillColor('black').text(aiDiagnosis);

            doc.end(); // Kết thúc nội dung

            // 🌟 ĐÃ FIX LỖI TYPESCRIPT: Định nghĩa rõ Promise<void> và bọc resolve lại
            await new Promise<void>((resolve, reject) => {
                writeStream.on('finish', () => resolve());
                writeStream.on('error', reject);
            });

            // Gắn link file vào Database sau khi chắc chắn file đã lưu xong
            newAppointment.aiDiagnosticPdf = `/uploads/pdfs/${fileName}`;
        } catch (error) {
            console.error("Lỗi khi xuất file PDF:", error);
            // Nếu có lỗi lúc tạo PDF thì vẫn cho phép lưu lịch khám, bỏ trống file
            newAppointment.aiDiagnosticPdf = null;
        }

        // 4. Lưu xuống Database
        return await this.appointmentRepo.save(newAppointment);
    }

    createPatient(): Promise<PatientEntity> {
        let newPatient = {
            name: 'Nguyen Van A',
            gender: 'male',
            age: 18,
            birthDate: new Date('2025-10-06'),
            email: 'abc@gmail.com',
            phone: '0111111111',
            address: '123 Le Van Huu',
            createAt: new Date(),
            avatar: 'link'
        }
        return this.patientRepo.save(newPatient);
    }

    async deleteAppointment(id: number): Promise<void> {
        await this.appointmentRepo.delete(id);
    }

    // Cập nhật thông tin bệnh nhân
    async updatePatient(id: number, updateData: Partial<PatientEntity>): Promise<PatientEntity> {
        await this.patientRepo.update(id, updateData);
        return this.getPatientById(id); 
    }

    editAppointment(appointmentId: number): Promise<any> {
        let newAppointment = {
            id: appointmentId,
            apTime: new Date('2025-08-18'),
            confirmDate: null,
            address: 'dia chi bac si',
            note: null,
            confirmCondition: 1,
            doctor: 'bac si Quy',
            patientId: 1,
            doctorId: 2
        };
        return Promise.resolve(newAppointment);
    }

    // Lấy danh sách lịch hẹn của bệnh nhân
    async listAppointment(patientId: number): Promise<AppointmentEntity[]> {
        return await this.appointmentRepo.find({ 
            where: { patient: { id: patientId } },
            order: { apTime: 'DESC' } 
        });
    }

    // Lấy thông tin bệnh nhân
    async getPatientById(id: number): Promise<PatientEntity> {
        const patient = await this.patientRepo.findOne({ 
            where: { id: id } 
        });
        if (!patient) {
            throw new NotFoundException(`Không tìm thấy hồ sơ bệnh nhân số ${id}`);
        }
        return patient;
    }

    // API 1: Sinh danh sách khung giờ khám cố định (15 phút/ca)
    getAvailableTimeSlots(): string[] {
        const slots: string[] = [];

        // Khung giờ Sáng: 07:00 đến 11:00 (Ca cuối buổi sáng là 10:45)
        for (let hour = 7; hour < 11; hour++) {
            for (let min = 0; min < 60; min += 15) {
                const formattedHour = hour.toString().padStart(2, '0');
                const formattedMin = min.toString().padStart(2, '0');
                slots.push(`${formattedHour}:${formattedMin}`);
            }
        }

        // Khung giờ Chiều: 13:00 đến 17:00 (Ca cuối buổi chiều là 16:45)
        for (let hour = 13; hour < 17; hour++) {
            for (let min = 0; min < 60; min += 15) {
                const formattedHour = hour.toString().padStart(2, '0');
                const formattedMin = min.toString().padStart(2, '0');
                slots.push(`${formattedHour}:${formattedMin}`);
            }
        }

        return slots;
    }

    // API 2: Lọc bác sĩ rảnh theo đúng ngày giờ bệnh nhân chọn
    async getAvailableDoctors(dateTimeString: string): Promise<any[]> {
        // 1. Gọi tất cả bác sĩ trong phòng khám
        const allDoctors = await this.doctorRepo.find();

        // 2. Tìm các lịch hẹn trùng chính xác với giờ này
        const busyAppointments = await this.appointmentRepo.find({
            where: {
                apTime: new Date(dateTimeString)
            }
        });

        // Chỉ lọc ra những lịch đang Chờ duyệt (0) hoặc Đã duyệt (1)
        const activeAppointments = busyAppointments.filter(app => app.confirmCondition !== 2);
        
        // Lấy ra danh sách ID của các bác sĩ đang kẹt lịch
        const busyDoctorIds = activeAppointments.map(app => app.doctorId);

        // 3. Trừ đi bác sĩ bận -> Ra bác sĩ rảnh
        const availableDoctors = allDoctors.filter(doc => !busyDoctorIds.includes(doc.id));

        return availableDoctors;
    }
    // 🌟 ĐĂNG KÝ TÀI KHOẢN
    async registerPatient(dto: any): Promise<any> {
        // Kiểm tra xem số điện thoại đã tồn tại chưa
        const existPatient = await this.patientRepo.findOne({ where: { phone: dto.phone } });
        if (existPatient) {
            return { success: false, message: "Số điện thoại này đã được đăng ký!" };
        }

        const newPatient = this.patientRepo.create();
        newPatient.name = dto.name;
        newPatient.phone = dto.phone;
        newPatient.password = dto.password; // Thực tế sau này Quý nên dùng bcrypt để mã hóa
        newPatient.createdAt = new Date();

        await this.patientRepo.save(newPatient);
        return { success: true, message: "Đăng ký thành công!", data: newPatient };
    }

    // 🌟 ĐĂNG NHẬP
    async loginPatient(phone: string, pass: string): Promise<any> {
        const patient = await this.patientRepo.findOne({ where: { phone: phone } });
        if (!patient) {
            return { success: false, message: "Không tìm thấy tài khoản với số điện thoại này!" };
        }

        if (patient.password !== pass) {
            return { success: false, message: "Mật khẩu không chính xác!" };
        }

        return { success: true, message: "Đăng nhập thành công!", data: patient };
    }
}