import { ApiProperty } from "@nestjs/swagger";
import { IsEmail, IsString } from "class-validator";

export class LoginDTO {
    @ApiProperty({ example: "patient@dacn.local" })
    @IsEmail()
    email: string;

    @ApiProperty({ example: "Test@123" })
    @IsString()
    password: string;
}
