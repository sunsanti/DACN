import { ApiProperty } from "@nestjs/swagger";
import { IsDate, IsNumber, IsString } from "class-validator";

export class DoctorDTO {
    @ApiProperty()
    @IsString()
    name: string;

    @ApiProperty()
    @IsNumber()
    age: number;

    @ApiProperty()
    @IsDate()
    dateOfBirth: Date

    @ApiProperty()
    @IsString()
    phone: string

    @ApiProperty()
    @IsString()
    address: string;

    @ApiProperty()
    @IsString()
    email: string
    
}