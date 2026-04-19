import { Appointment } from "src/patient/dto/appointment.dto";

export interface IDoctorService {
    listUnacceptedAppointment(): Promise<Appointment[]>;
    listAcceptedAppointment(): Promise<Appointment[]>;
    addWorkingTime(): Promise<Date>;
    // cancelAppointment(appointment: Appointment): Promise<void>;
    cancelShift(): Promise<void>;
    reAppointment(appointmentId: number): Promise<Appointment>;
    confirmAppointment(): Promise<Appointment>;
}