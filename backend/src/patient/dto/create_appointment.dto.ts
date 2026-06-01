import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsDateString } from 'class-validator';

export class CreateAppoinmentDTO {
    @ApiProperty()
    @IsDateString()
    apTime!: Date;

    @ApiProperty()
    @IsString()
    address!: string;
}