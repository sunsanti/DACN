export interface Shift {
    id: number;
    doctorId: number;
    type: 'morning' | 'afternoon';
    startTime: Date;
    endTime: Date;
    emergency: number;
}