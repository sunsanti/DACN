import { Injectable, NotFoundException } from "@nestjs/common";
import { IPatientService } from "./interfaces/patient_service.interface";
import { PatientDTO } from "./dto/patient.dto";
import { Patient } from "./interfaces/patient.interface";
import { Appointment } from "./interfaces/appointment.interface";
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";
import { InjectRepository } from "@nestjs/typeorm";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { Repository } from "typeorm";
import { PatientEntity } from "./entities/patient.entity";
import { Doctor } from "src/doctor/interfaces/doctor.interface";
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

    async deleteAppointment(id: number): Promise<void> {
        await this.appointmentRepo.delete(id);
    }

    editAppointment(appointmentId: number): Promise<Appointment> {
        let newAppointment: Appointment = {
            id: appointmentId,
            apTime: new Date('2025-08-18'),
            confirmDate: null,
            address: 'dia chi bac si',
            note: null,
            confirmCondition: 1,
            doctor: 'bac si Quy',
            patientId: 1,
            doctorId: 2
        }
        return Promise.resolve(newAppointment);
    }

    async listAppointment(patientId: number): Promise<AppointmentEntity[]> {
        return this.appointmentRepo.find({
            where: { patient: { id: patientId } },
            relations: ['doctor'],
            order: { apTime: 'DESC' },
        });
    }
    

}