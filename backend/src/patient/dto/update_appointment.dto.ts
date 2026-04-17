import { IsString, IsInt, IsDate, IsOptional} from 'class-validator'

export class UpdateAppointmentDTO {
    @IsString()
    @IsOptional()
    name?: string;

    @IsDate()
    @IsOptional()
    apTime?: Date;

    @IsString()
    @IsOptional()
    address: string;

    @IsString()
    @IsOptional()
    doctor: string;
}