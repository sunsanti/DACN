import { ApiProperty } from '@nestjs/swagger';
import { IsInt,IsDate,IsString } from 'class-validator'

export class CreateAppoinmentDTO {

    @ApiProperty()
    @IsDate()
    apTime: Date;

    @ApiProperty()
    doctor: string;

    @ApiProperty()
    address: string;
}