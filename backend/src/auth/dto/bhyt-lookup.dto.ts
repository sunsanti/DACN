import { ApiProperty } from "@nestjs/swagger";
import { IsDateString, Matches } from "class-validator";

export class BhytLookupDto {
    @ApiProperty({ example: "079012345689" })
    @Matches(/^\d{12}$/, { message: "CCCD gồm đúng 12 chữ số" })
    cccd: string;

    @ApiProperty({ example: "2000-01-01" })
    @IsDateString({ strict: true }, { message: "Ngày sinh không hợp lệ" })
    birthDate: string;
}
