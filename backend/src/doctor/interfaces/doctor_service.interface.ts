import { Appointment } from "src/patient/interfaces/appointment.interface";
import { Shift } from "./shift.interface";
import { DoctorEntity } from "../entities/doctor.entity";
import { ShiftEntity } from "../entities/shift.entity";
import { AppointmentEntity } from "src/patient/entities/appointment.entity";
import { ConfirmAppointmentDTO } from "../dto/confirm.dto";

export interface IDoctorService {
    createDoctor(): Promise<DoctorEntity>;
    listUnacceptedAppointment(): Promise<AppointmentEntity[]>;
    listAcceptedAppointment(): Promise<AppointmentEntity[]>;
    addWorkingTime(): Promise<DoctorEntity>;
    // cancelAppointment(appointment: Appointment): Promise<void>;
    cancelShift(doctorId: number, shiftId: number): Promise<void>;
    reAppointment(appointmentId: number, newApTime: Date, newConfirmDate: Date, newNote: string): Promise<AppointmentEntity>;
    confirmAppointment(appointmentId: number, note: string, confirmDate: Date): Promise<AppointmentEntity>;
    calculateTime(): Promise<void>;
}