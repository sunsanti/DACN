import { ApiProperty } from "@nestjs/swagger";
import { Type } from "class-transformer";
import { IsDate, IsString } from "class-validator";

export class ReAppointmentDTO {
    @ApiProperty({ example: "2026-08-05T09:00:00.000Z" })
    @Type(() => Date)
    @IsDate()
    newApTime: Date;

    @ApiProperty({ example: "2026-08-04T09:00:00.000Z" })
    @Type(() => Date)
    @IsDate()
    newConfirmTime: Date;

    @ApiProperty()
    @IsString()
    newNote: string;
}