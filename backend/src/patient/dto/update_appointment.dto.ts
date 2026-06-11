import { ApiProperty } from "@nestjs/swagger";
import { IsString, IsDateString, IsOptional } from "class-validator";

export class UpdateAppointmentDTO {
    @ApiProperty({ required: false, example: "2026-08-10T09:00:00.000Z" })
    @IsDateString()
    @IsOptional()
    apTime?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    address?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    note?: string;
}
