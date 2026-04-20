import { IsEmail, IsInt, IsDate, IsString } from 'class-validator';

export class PatientDTO {
    @IsInt()
    id: number;

    @IsInt()
    age: number;

    @IsEmail()
    email: string;

    @IsDate()
    date: Date;

    @IsString()
    name: string;

    @IsString()
    phone: string;

    @IsString()
    address: string;
}