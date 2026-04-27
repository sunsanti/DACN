import { Doctor } from "src/doctor/interfaces/doctor.interface";
import { CreateAppoinmentDTO } from "../dto/create_appointment.dto";
import { PatientDTO } from "../dto/patient.dto";
import { Appointment } from "./appointment.interface";
import { Patient } from "./patient.interface";
import { PatientEntity } from "../entities/patient.entity";
import { AppointmentEntity } from "../entities/appointment.entity";

export interface IPatientService {
    setAppointment(dto: CreateAppoinmentDTO): Promise<AppointmentEntity>;
    createPatient(): Promise<PatientEntity>;
    // findByFilter(filter: {date?: Date; apName: string});
    deleteAppointment(id: number): Promise<void>;
    editAppointment(id: number): Promise<Appointment>;
    listAppointment(patientId: number): Promise<AppointmentEntity[]>;
    // createPatient(dto: PatientDTO): Promise<Patient>;
}