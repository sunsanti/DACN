import { ApiProperty } from "@nestjs/swagger";
import { IsEmail, IsInt, IsOptional, IsString, IsDateString } from "class-validator";

export class UpdateDoctorDTO {
    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    name?: string;

    @ApiProperty({ required: false })
    @IsInt()
    @IsOptional()
    age?: number;

    @ApiProperty({ required: false, example: "1990-01-01" })
    @IsDateString()
    @IsOptional()
    dateOfBirth?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    gender?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    phone?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    address?: string;

    @ApiProperty({ required: false })
    @IsEmail()
    @IsOptional()
    email?: string;
}
