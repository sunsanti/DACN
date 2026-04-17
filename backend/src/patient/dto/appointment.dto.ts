import { ApiProperty } from '@nestjs/swagger';

export class Appointment {
    @ApiProperty()
    id: number;

    @ApiProperty()
    apTime: Date;

    @ApiProperty()
    address: string;

    @ApiProperty()
    doctor: string;

    @ApiProperty()
    patientId: number;
}