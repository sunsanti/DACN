import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
import { IPatientService } from "./interfaces/patient_service.interface";
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";
import { UpdateAppointmentDTO } from "./dto/update_appointment.dto";
import { UpdatePatientDTO } from "./dto/update_patient.dto";
import { InjectRepository } from "@nestjs/typeorm";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { Repository } from "typeorm";
import { PatientEntity } from "./entities/patient.entity";
import { DoctorEntity } from "src/doctor/entities/doctor.entity";

@Injectable()
export class PatientService implements IPatientService {
    constructor(
        @InjectRepository(AppointmentEntity)
        private appointmentRepo: Repository<AppointmentEntity>,

        @InjectRepository(PatientEntity)
        private patientRepo: Repository<PatientEntity>,

        @InjectRepository(DoctorEntity)
        private doctorRepo: Repository<DoctorEntity>
    ) {}
    // private patiens: Patient[] = [
    //     {id: 1, name: 'Nguyen Van A', gender: 'male', age: 18, birthDate: new Date('2025-10-06'), email: 'abc@gmail.com', phone: '011111111', address: 'abc', createAt: new Date('2024-18-05'), avatar: 'abcs'}
    // ];

    async setAppointment(patientId: number, dto: CreateAppoinmentDTO): Promise<AppointmentEntity> {
        const doctor = await this.doctorRepo.findOne({ where: { id: dto.doctorId } });
        if (!doctor) throw new NotFoundException('Bác sĩ không tồn tại');

        return this.appointmentRepo.save({
            apTime: new Date(dto.apTime),
            confirmDate: null,
            address: dto.address,
            note: dto.note ?? null,
            confirmCondition: 1, // 1 = chờ xác nhận (critical-constraints rule 3)
            doctorName: doctor.name,
            patient: { id: patientId } as PatientEntity,
            doctor: { id: dto.doctorId } as DoctorEntity,
        });
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

    /** Own profile. */
    async getProfile(patientId: number): Promise<PatientEntity> {
        const patient = await this.patientRepo.findOne({ where: { id: patientId } });
        if (!patient) throw new NotFoundException('Không tìm thấy hồ sơ bệnh nhân');
        return patient;
    }

    async updateProfile(patientId: number, dto: UpdatePatientDTO): Promise<PatientEntity> {
        const patient = await this.getProfile(patientId);
        Object.assign(patient, {
            ...dto,
            birthDate: dto.birthDate ? new Date(dto.birthDate) : patient.birthDate,
        });
        return this.patientRepo.save(patient);
    }

    /** Ensure the appointment belongs to this patient (prevent IDOR). */
    private async assertOwns(patientId: number, appointmentId: number): Promise<AppointmentEntity> {
        const appt = await this.appointmentRepo.findOne({
            where: { id: appointmentId },
            relations: ['patient', 'doctor'],
        });
        if (!appt) throw new NotFoundException('Lịch khám không tồn tại');
        if (appt.patient?.id !== patientId) throw new ForbiddenException('Không phải lịch của bạn');
        return appt;
    }

    async getAppointment(patientId: number, appointmentId: number): Promise<AppointmentEntity> {
        return this.assertOwns(patientId, appointmentId);
    }

    /** Cancel (not delete) with a reason — keeps the row so the doctor sees it. */
    async cancelAppointment(patientId: number, id: number, reason: string): Promise<AppointmentEntity> {
        const appt = await this.assertOwns(patientId, id);
        if (appt.cancelReason) throw new BadRequestException('Lịch đã bị hủy');
        await this.appointmentRepo.update(
            { id },
            { cancelReason: reason, canceledBy: 'patient' },
        );
        return this.getAppointment(patientId, id);
    }

    /**
     * Reschedule to a new slot — allowed ONCE. If the appointment was already
     * confirmed, it goes back to pending so the doctor re-confirms the new time.
     */
    async rescheduleAppointment(patientId: number, appointmentId: number, dto: UpdateAppointmentDTO): Promise<AppointmentEntity> {
        const appt = await this.assertOwns(patientId, appointmentId);
        if (appt.cancelReason) throw new BadRequestException('Lịch đã bị hủy');
        if (appt.rescheduled) throw new BadRequestException('Lịch chỉ được đổi 1 lần — chỉ có thể hủy');
        if (appt.confirmCondition === 2) throw new BadRequestException('Lịch đã khám xong');
        if (!dto.apTime) throw new BadRequestException('Thiếu khung giờ mới');

        await this.appointmentRepo.update(
            { id: appointmentId },
            {
                apTime: new Date(dto.apTime),
                ...(dto.note !== undefined ? { note: dto.note } : {}),
                confirmCondition: 1, // back to pending (doctor must re-confirm)
                confirmDate: null,
                rescheduled: true,
            },
        );
        return this.getAppointment(patientId, appointmentId);
    }

    async listAppointment(patientId: number): Promise<AppointmentEntity[]> {
        // Includes canceled ones so the patient can see the cancel reason.
        return this.appointmentRepo.find({
            where: { patient: { id: patientId } },
            relations: ['doctor'],
            order: { apTime: 'DESC' },
        });
    }
}