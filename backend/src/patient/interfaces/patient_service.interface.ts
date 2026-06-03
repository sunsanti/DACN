import { CreateAppoinmentDTO } from "../dto/create_appointment.dto";
import { UpdateAppointmentDTO } from "../dto/update_appointment.dto";
import { UpdatePatientDTO } from "../dto/update_patient.dto";
import { PatientEntity } from "../entities/patient.entity";
import { AppointmentEntity } from "../entities/appointment.entity";

export interface IPatientService {
    setAppointment(patientId: number, dto: CreateAppoinmentDTO): Promise<AppointmentEntity>;
    createPatient(): Promise<PatientEntity>;
    getProfile(patientId: number): Promise<PatientEntity>;
    updateProfile(patientId: number, dto: UpdatePatientDTO): Promise<PatientEntity>;
    getAppointment(patientId: number, appointmentId: number): Promise<AppointmentEntity>;
    cancelAppointment(patientId: number, id: number, reason: string): Promise<AppointmentEntity>;
    rescheduleAppointment(patientId: number, appointmentId: number, dto: UpdateAppointmentDTO): Promise<AppointmentEntity>;
    listAppointment(patientId: number): Promise<AppointmentEntity[]>;
}
