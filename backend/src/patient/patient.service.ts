import { Inject, Injectable } from "@nestjs/common";
import { IPatientService } from "./interfaces/patient_service.interface";
import { PatientDTO } from "./dto/patient.dto";
import { Patient } from "./interfaces/patient.interface";
import { Appointment } from "./interfaces/appointment.interface";
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";

@Injectable()
export class PatientService implements IPatientService {
    private patiens: Patient[] = [
        {id: 1, name: 'Nguyen Van A', age: 18, birthDate: '2004-18-8', email: 'abc@gmail.com', phone: '011111111', address: 'abc', createAt: new Date('2024-18-05'), avatar: 'abcs'}
    ];

    setAppointment(dto: CreateAppoinmentDTO): Promise<Appointment> {
        let docter = 'quan';
        let timeInput = '26-05-2026';
        const [day,month,year] = timeInput.split('-');

        const date = new Date(`${year}-${month}-${day}`);
        let appointment: Appointment = 
            {
                id: 1,
                apTime: new Date('2026-10-11'),
                address: 'abc Mac Dinh',
                doctor: 'Quan',
                patientId: 1
            }

        return Promise.resolve(appointment);
    }

    deleteAppointment(id: number): Promise<{ message: string }> {
        return Promise.resolve({ message: `Delete ${id}` });
    }

    editAppointment(appointmentId: number): Promise<Appointment> {
        let newAppointment: Appointment = {
            id: appointmentId,
            apTime: new Date('2025-08-18'),
            address: 'dia chi bac si',
            doctor: 'bac si Quy',
            patientId: 1
        }
        return Promise.resolve(newAppointment);
    }

    listAppointment(patientId: number): Promise<Appointment[]> {
        //fix this function by finding with patientId
        let appointment: Appointment[] = [
            {
                id: 1,
                apTime: new Date('2026-10-11'),
                address: 'abc Mac Dinh',
                doctor: 'Quan',
                patientId: 1
            },
            {
                id: 2,
                apTime: new Date('2026-10-11'),
                address: 'abc Mac Dinh',
                doctor: 'Quan',
                patientId: 1
            }
        ];
        return Promise.resolve(appointment);
    }

}