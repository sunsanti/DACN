import { AppointmentEntity } from "../entities/appointment.entity";
import { PatientEntity } from "../entities/patient.entity";

export interface IPatientService {
    setAppointment(dto: any): Promise<AppointmentEntity>;
    createPatient(): Promise<PatientEntity>;
    deleteAppointment(id: number): Promise<void>;
    updatePatient(id: number, updateData: Partial<PatientEntity>): Promise<PatientEntity>;
    editAppointment(appointmentId: number): Promise<any>;
    
    // Đã thêm dấu [] để báo đây là danh sách nhiều lịch hẹn
    listAppointment(patientId: number): Promise<AppointmentEntity[]>; 
    
    // Bổ sung hàm lấy bệnh nhân
    getPatientById(id: number): Promise<PatientEntity>;
}