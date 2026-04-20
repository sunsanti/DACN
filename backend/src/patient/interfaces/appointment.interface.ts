export interface Appointment {
    id: number;
    apTime: Date;
    confirmDate?: Date | null;
    address: string;
    note?: string | null;
    confirmCondition?: number;
    doctor: string;
    patientId: number;
    doctorId: number;
}