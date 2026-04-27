import { Inject, Injectable } from "@nestjs/common";
import { IPatientService } from "./interfaces/patient_service.interface";
import { PatientDTO } from "./dto/patient.dto";
import { Patient } from "./interfaces/patient.interface";
import { Appointment } from "./interfaces/appointment.interface";
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";
import { InjectRepository } from "@nestjs/typeorm";
import { AppointmentEntity } from "./entities/appointment.entity";
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
        private patientRepo: Repository<PatientEntity>
    ) {}
    // private patiens: Patient[] = [
    //     {id: 1, name: 'Nguyen Van A', gender: 'male', age: 18, birthDate: new Date('2025-10-06'), email: 'abc@gmail.com', phone: '011111111', address: 'abc', createAt: new Date('2024-18-05'), avatar: 'abcs'}
    // ];

    setAppointment(dto: CreateAppoinmentDTO): Promise<AppointmentEntity> {
        let docter = 'quan';
        let timeInput = '26-05-2026';
        const [day,month,year] = timeInput.split('-');

        const date = new Date(`${year}-${month}-${day}`);
        let appointment: AppointmentEntity = 
            {
                id: 1,
                apTime: new Date('2026-10-11'),
                confirmDate: null,
                address: 'abc Mac Dinh',
                note: null,
                confirmCondition: 0,
                doctorName: 'Quan',
                patient: {id: 1} as PatientEntity,
                doctor: {id: 1} as DoctorEntity
            }
        return this.appointmentRepo.save(appointment);
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
        //fix this function by finding with patientId
        // let appointment: Appointment[] = [
        //     {
        //         id: 1,
        //         apTime: new Date('2026-10-11'),
        //         confirmDate: null,
        //         address: 'abc Mac Dinh',
        //         note: null,
        //         confirmCondition: 1,
        //         doctor: 'Quan',
        //         patientId: 1,
        //         doctorId: 1
        //     },
        //     {
        //         id: 2,
        //         apTime: new Date('2026-10-11'),
        //         confirmDate: new Date('2026-10-11'),
        //         address: 'abc Mac Dinh',
        //         note: 'Benh nhan bi abc, xyz',
        //         confirmCondition: 0,
        //         doctor: 'Quan',
        //         patientId: 1,
        //         doctorId: 1
        //     }
        // ];
        const user: AppointmentEntity[] = await this.appointmentRepo.find({ where: { patient: { id: 1} } });
        return user;
    }

    // createPatient(dto: PatientDTO): Promise<Patient> {
    //     return Promise.resolve({} as Patient);
    // }

}