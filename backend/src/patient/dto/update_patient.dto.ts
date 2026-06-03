import { ApiProperty } from "@nestjs/swagger";
import { IsEmail, IsInt, IsOptional, IsString, IsDateString } from "class-validator";

export class UpdatePatientDTO {
    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    name?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    gender?: string;

    @ApiProperty({ required: false })
    @IsInt()
    @IsOptional()
    age?: number;

    @ApiProperty({ required: false, example: "2000-01-01" })
    @IsDateString()
    @IsOptional()
    birthDate?: string;

    @ApiProperty({ required: false })
    @IsEmail()
    @IsOptional()
    email?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    phone?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    address?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    avatar?: string;
}
