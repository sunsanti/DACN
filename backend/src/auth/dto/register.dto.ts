import { ApiProperty } from "@nestjs/swagger";
import { Transform, Type } from "class-transformer";
import {
    IsDateString,
    Matches,
    IsEmail,
    IsInt,
    IsString,
    MinLength,
} from "class-validator";

export class RegisterDTO {
    /** CCCD 12 số (bắt buộc). BHYT được tra theo CCCD trong danh bạ, bệnh nhân không tự khai thẻ. */
    @ApiProperty({ example: "079203000111" })
    @Transform(({ value }: { value: unknown }) => (typeof value === "string" ? value.replace(/\s+/g, "") : value))
    @Matches(/^\d{12}$/, { message: "CCCD phải gồm đúng 12 chữ số" })
    cccd: string;

    @ApiProperty({ example: "patient@dacn.local" })
    @IsEmail()
    email: string;

    @ApiProperty({ example: "Test@123" })
    @IsString()
    @MinLength(6)
    password: string;

    @ApiProperty({ example: "Nguyen Van A" })
    @IsString()
    name: string;

    @ApiProperty({ example: "male" })
    @IsString()
    gender: string;

    @ApiProperty({ example: 20 })
    @Type(() => Number) // multipart gửi mọi field dạng string
    @IsInt()
    age: number;

    @ApiProperty({ example: "2005-01-01" })
    @IsDateString()
    birthDate: string;

    @ApiProperty({ example: "0900000000" })
    @IsString()
    phone: string;

    @ApiProperty({ example: "123 Le Van Huu" })
    @IsString()
    address: string;
}
