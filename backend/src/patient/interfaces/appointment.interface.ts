export interface Appointment {
    id: number;
    apTime: Date;
    confirmDate: Date;
    address: string;
    note: string
    confirmCondition: number;
    doctor: string;
    patientId: number;
    doctorId: number
}