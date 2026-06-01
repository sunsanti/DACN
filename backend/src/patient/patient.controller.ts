import { Controller, Post, Body, Get, Delete, Param, Put, Patch, Query } from "@nestjs/common";
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";
import { PatientService } from "./patient.service";
import { ApiTags } from "@nestjs/swagger";
import { PatientEntity } from "./entities/patient.entity";
import { AppointmentEntity } from "./entities/appointment.entity";

@ApiTags('patient')
@Controller('patient')
export class PatientController {
    constructor(private readonly patientService: PatientService) {}

    // =================================================================
    // 🚀 Nhóm 1: CÁC ROUTE CỐ ĐỊNH (Bắt buộc phải đặt trên cùng để tránh trùng)
    // =================================================================

    @Get('time-slots')
    getTimeSlots() {
        return this.patientService.getAvailableTimeSlots();
    }

    @Get('available-doctors')
    async getAvailableDoctors(@Query('dateTime') dateTime: string) {
        // dateTime gửi từ Flutter có dạng chuẩn: "2026-10-25 08:15:00"
        return this.patientService.getAvailableDoctors(dateTime);
    }

    // =================================================================
    // ➕ Nhóm 2: CÁC ROUTE POST (Tạo mới dữ liệu)
    // =================================================================

    @Post('create-appointment')
    setAppointment(@Body() dto: CreateAppoinmentDTO) {
        return this.patientService.setAppointment(dto);
    }

    @Post('create-patient')
    createPatient(): Promise<PatientEntity> {
        return this.patientService.createPatient();
    }

    // =================================================================
    // 🔍 Nhóm 3: CÁC ROUTE ĐỘNG CÓ CHỨA :id (Phải đặt ở dưới cùng)
    // =================================================================

    @Get(':id')
    getPatientProfile(@Param('id') id: string): Promise<PatientEntity> {
        return this.patientService.getPatientById(Number(id));
    }

    @Patch(':id')
    updatePatient(@Param('id') id: string, @Body() updateData: Partial<PatientEntity>) {
        return this.patientService.updatePatient(Number(id), updateData);
    }

    @Get(':id/appointments')
    async listAppointment(@Param('id') patientId: string): Promise<AppointmentEntity[]> {
        return this.patientService.listAppointment(Number(patientId));
    }

    @Delete('delete-appointment/:id')
    async deleteAppointment(@Param('id') id: string) {
        // Đã sửa: Ép kiểu string sang Number để khớp với Service
        return this.patientService.deleteAppointment(Number(id));
    }

    @Put('edit-appointment/:id')
    editAppointment(@Param('id') appointmentId: string) {
        // Đã sửa: Ép kiểu string sang Number để khớp với Service
        return this.patientService.editAppointment(Number(appointmentId));
    }
    @Post('register')
    async register(@Body() dto: any) {
        return await this.patientService.registerPatient(dto);
    }

    @Post('login')
    async login(@Body() body: any) {
        return await this.patientService.loginPatient(body.phone, body.password);
    }
}