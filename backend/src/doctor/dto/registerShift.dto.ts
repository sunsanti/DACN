import { ApiProperty } from "@nestjs/swagger";
import { IsInt, Matches } from "class-validator";

export class RegisterShiftDTO {
    @ApiProperty({ example: 1 })
    @IsInt()
    shiftId: number;

    @ApiProperty({ example: "2026-06-10" })
    @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: "date phải dạng YYYY-MM-DD" })
    date: string;
}
