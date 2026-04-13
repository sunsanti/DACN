import { IsEmail, IsInt, IsDate, IsNumber } from 'class-validator';

export class PatientDTO {
    @IsInt()
    id: number;

    @IsNumber()
    age: number;

    @IsEmail()
    email: string;

    @IsDate()
    date: Date
}