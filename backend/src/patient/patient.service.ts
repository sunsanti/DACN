import { ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
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

    async deleteAppointment(patientId: number, id: number): Promise<void> {
        await this.assertOwns(patientId, id);
        await this.appointmentRepo.delete(id);
    }

    async editAppointment(patientId: number, appointmentId: number, dto: UpdateAppointmentDTO): Promise<AppointmentEntity> {
        await this.assertOwns(patientId, appointmentId);
        await this.appointmentRepo.update(
            { id: appointmentId },
            {
                ...(dto.apTime ? { apTime: new Date(dto.apTime) } : {}),
                ...(dto.address !== undefined ? { address: dto.address } : {}),
                ...(dto.note !== undefined ? { note: dto.note } : {}),
            },
        );
        const updated = await this.appointmentRepo.findOne({
            where: { id: appointmentId },
            relations: ['doctor'],
        });
        if (!updated) throw new NotFoundException('Lịch khám không tồn tại');
        return updated;
    }

    async listAppointment(patientId: number): Promise<AppointmentEntity[]> {
        return this.appointmentRepo.find({
            where: { patient: { id: patientId } },
            relations: ['doctor'],
            order: { apTime: 'DESC' },
        });
    }
}