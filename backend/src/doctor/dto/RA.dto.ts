import { ApiProperty } from "@nestjs/swagger";
import { IsDate, IsString } from "class-validator";

export class ReAppointmentDTO {
    @ApiProperty()
    @IsDate()
    newApTime: Date;

    @ApiProperty()
    @IsDate()
    newConfirmTime: Date;

    @ApiProperty()
    @IsString()
    newNote: string;
}