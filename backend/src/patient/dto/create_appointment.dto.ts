import { IsInt,IsDate,IsString } from 'class-validator'

export class CreateAppoinmentDTO {
    @IsString()
    name: string;

    @IsDate()
    apTime: Date;

    @IsDate()
    apDate: Date;

    @IsString()
    address: string;

    @IsString()
    doctor: string;
}