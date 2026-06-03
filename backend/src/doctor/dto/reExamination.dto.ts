import { ApiProperty } from "@nestjs/swagger";
import { IsDateString, IsInt, IsOptional, IsString } from "class-validator";

export class ReExaminationDTO {
    @ApiProperty({ example: 1 })
    @IsInt()
    patientId: number;

    @ApiProperty({ example: "2026-09-01T09:00:00.000Z" })
    @IsDateString()
    apTime: string;

    @ApiProperty()
    @IsString()
    address: string;

    @ApiProperty({ required: false })
    @IsOptional()
    @IsString()
    note?: string;
}
