import { CreateAppoinmentDTO } from "../dto/create_appointment.dto";
import { PatientDTO } from "../dto/patient.dto";
import { Appointment } from "./appointment.interface";
import { Patient } from "./patient.interface";

export interface IPatientService {
    setAp(dto: CreateAppoinmentDTO): Promise<Appointment>;
    // findByFilter(filter: {date?: Date; apName: string});
    deleteAp(id: number): Promise<void>;
    editAp(id: number): Promise<Appointment>;
}