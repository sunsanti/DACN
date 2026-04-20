import { CreateAppoinmentDTO } from "../dto/create_appointment.dto";
import { PatientDTO } from "../dto/patient.dto";
import { Appointment } from "./appointment.interface";
import { Patient } from "./patient.interface";

export interface IPatientService {
    setAppointment(dto: CreateAppoinmentDTO): Promise<Appointment>;
    // findByFilter(filter: {date?: Date; apName: string});
    deleteAppointment(id: number): Promise<{message: string}>;
    editAppointment(id: number): Promise<Appointment>;
    listAppointment(patientId: number): Promise<Appointment[]>;
}