import { ApiProperty } from "@nestjs/swagger";
import { Type } from "class-transformer";
import { IsDate, IsString } from "class-validator";

export class ConfirmAppointmentDTO {
    @ApiProperty()
    @IsString()
    note: string;

    @ApiProperty({ example: "2026-07-30T10:00:00.000Z" })
    @Type(() => Date) // transform ISO string -> Date before validation
    @IsDate()
    confirmDate: Date;
}