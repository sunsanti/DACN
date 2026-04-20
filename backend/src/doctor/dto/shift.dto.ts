import { ApiProperty } from "@nestjs/swagger";
import { IsDate, IsNumber, IsString } from "class-validator";

export class ShiftDTO {
    @ApiProperty()
    @IsString()
    type: string;

    @ApiProperty()
    @IsDate()
    startTime: Date;

    @ApiProperty()
    @IsDate()
    endTime: Date;

    @ApiProperty()
    @IsNumber()
    emergency: number;
}