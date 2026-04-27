import { IsEmail, IsInt, IsDate, IsString } from 'class-validator';

export class PatientDTO {

    @IsString()
    name: string;

    @IsString()
    gender: string;

    @IsInt()
    age: number;

    @IsDate()
    birthDate: Date;

    @IsEmail()
    email: string;

    @IsString()
    phone: string;

    @IsString()
    address: string;
}