export interface shift {
    id: number;
    doctorId: number;
    type: 'morning' | 'afternoon';
    startTime: string;
    endTime: string;
    emergency: number;
}