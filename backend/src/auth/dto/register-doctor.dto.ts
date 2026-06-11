import { ApiProperty } from "@nestjs/swagger";
import {
    IsDateString,
    IsEmail,
    IsInt,
    IsString,
    MinLength,
} from "class-validator";

export class RegisterDoctorDTO {
    @ApiProperty({ example: "doctor@dacn.local" })
    @IsEmail()
    email: string;

    @ApiProperty({ example: "Doctor@123" })
    @IsString()
    @MinLength(6)
    password: string;

    @ApiProperty({ example: "BS. Tran Van B" })
    @IsString()
    name: string;

    @ApiProperty({ example: 35 })
    @IsInt()
    age: number;

    @ApiProperty({ example: "1990-01-01" })
    @IsDateString()
    dateOfBirth: string;

    @ApiProperty({ example: "male" })
    @IsString()
    gender: string;

    @ApiProperty({ example: "0900000002" })
    @IsString()
    phone: string;

    @ApiProperty({ example: "Phong kham X" })
    @IsString()
    address: string;
}
