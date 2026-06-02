import { ApiProperty } from "@nestjs/swagger";
import {
    IsDateString,
    IsEmail,
    IsInt,
    IsString,
    MinLength,
} from "class-validator";

export class RegisterDTO {
    @ApiProperty({ example: "patient@dacn.local" })
    @IsEmail()
    email: string;

    @ApiProperty({ example: "Test@123" })
    @IsString()
    @MinLength(6)
    password: string;

    @ApiProperty({ example: "Nguyen Van A" })
    @IsString()
    name: string;

    @ApiProperty({ example: "male" })
    @IsString()
    gender: string;

    @ApiProperty({ example: 20 })
    @IsInt()
    age: number;

    @ApiProperty({ example: "2005-01-01" })
    @IsDateString()
    birthDate: string;

    @ApiProperty({ example: "0900000000" })
    @IsString()
    phone: string;

    @ApiProperty({ example: "123 Le Van Huu" })
    @IsString()
    address: string;
}
