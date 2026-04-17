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

    setAp(dto: CreateAppoinmentDTO): Promise<Appointment> {
        let name = 'ahihi'; //this will be name of the appointment
        let docter = 'quan';
        let timeInput = '26-05-2026';
        const [day,month,year] = timeInput.split('-');

        const date = new Date(`${year}-${month}-${day}`);
        console.log(date)
        return Promise.resolve({} as Appointment);
    }

    deleteAp(id: number): Promise<void> {
        return Promise.resolve();
    }

    editAp(id: number): Promise<Appointment> {
        return Promise.resolve({} as Appointment);
    }
}