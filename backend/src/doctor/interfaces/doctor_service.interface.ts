import { Appointment } from "src/patient/interfaces/appointment.interface";
import { Shift } from "./shift.interface";
import { DoctorEntity } from "../entities/doctor.entity";

export interface IDoctorService {
    createDoctor(): Promise<DoctorEntity>;
    listUnacceptedAppointment(): Promise<Appointment[]>;
    listAcceptedAppointment(): Promise<Appointment[]>;
    addWorkingTime(): Promise<Shift[]>;
    // cancelAppointment(appointment: Appointment): Promise<void>;
    cancelShift(): Promise<void>;
    reAppointment(appointmentId: number): Promise<Appointment>;
    confirmAppointment(): Promise<Appointment>;
}