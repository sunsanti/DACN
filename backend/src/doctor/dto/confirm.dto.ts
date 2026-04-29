import { ApiProperty } from "@nestjs/swagger";
import { IsDate, IsString } from "class-validator";

export class ConfirmAppointmentDTO {
    @ApiProperty()
    @IsString()
    note: string;

    @ApiProperty()
    @IsDate()
    confirmDate: Date;
}