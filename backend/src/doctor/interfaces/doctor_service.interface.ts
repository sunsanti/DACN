import { Appointment } from "src/patient/interfaces/appointment.interface";
import { Shift } from "./shift.interface";
import { DoctorEntity } from "../entities/doctor.entity";
import { ShiftEntity } from "../entities/shift.entity";
import { AppointmentEntity } from "../../patient/entities/appointment.entity";
import { ConfirmAppointmentDTO } from "../dto/confirm.dto";
import { ShiftAssignmentEntity } from "../entities/shiftAssignment.entity";
import { ShiftDTO } from "../dto/shift.dto";

export interface IDoctorService {
    createDoctor(): Promise<DoctorEntity>;
    listDoctors(): Promise<DoctorEntity[]>;
    //appointment (scoped to the logged-in doctor)
    listUnacceptedAppointment(doctorId: number): Promise<AppointmentEntity[]>;
    listAcceptedAppointment(doctorId: number): Promise<AppointmentEntity[]>;
    getReport(appointmentId: number): Promise<Buffer | null>;
    //shifts
    addWorkingTime(doctorId: number,shifts: ShiftDTO[]): Promise<ShiftAssignmentEntity[]>;
    deleteShift(doctorId: number, shiftId: number): Promise<void>;
    listOfShifts(doctorId: number): Promise<ShiftAssignmentEntity[]>;
    cancelShift(doctorId: number, shiftId: number): Promise<void>;
    reAppointment(doctorId: number, appointmentId: number, newApTime: Date, newConfirmDate: Date, newNote: string): Promise<AppointmentEntity>;
    confirmAppointment(doctorId: number, appointmentId: number, note: string, confirmDate: Date): Promise<AppointmentEntity>;
    calculateTime(): Promise<void>;
}