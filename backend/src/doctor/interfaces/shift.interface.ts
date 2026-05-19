export interface Shift {
    id: number;
    doctorId: number;
    type: string;
    startTime: Date;
    endTime: Date;
    emergency: number;
}