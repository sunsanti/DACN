import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsString, IsDateString, IsOptional } from 'class-validator'

export class CreateAppoinmentDTO {

    @ApiProperty()
    @IsDateString()
    apTime: Date;

    @ApiProperty()
    @IsString()
    address: string;

    @ApiProperty({ example: 1 })
    @IsInt()
    doctorId: number;

    @ApiProperty({ required: false })
    @IsOptional()
    @IsString()
    note?: string;
}