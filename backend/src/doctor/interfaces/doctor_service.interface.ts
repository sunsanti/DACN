// Sửa lại đường dẫn import trỏ về Entity thật thay vì Interface cũ
import { Appointment } from "../../patient/entities/appointment.entity";
import { Shift } from "../entities/shift.entity";

export interface IDoctorService {
    listUnacceptedAppointment(): Promise<Appointment[]>;

    listAcceptedAppointment(): Promise<Appointment[]>;

    // Thêm tham số shiftData
    addWorkingTime(shiftData: Partial<Shift>): Promise<Shift[]>;

    // Thêm tham số shiftId
    cancelShift(shiftId: number): Promise<void>;

    // Đã có sẵn tham số appointmentId, giữ nguyên
    reAppointment(appointmentId: number): Promise<Appointment>;

    // Thêm tham số appointmentId
    confirmAppointment(appointmentId: number): Promise<Appointment>;
}