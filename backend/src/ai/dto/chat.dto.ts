import { ApiProperty } from "@nestjs/swagger";
import { IsNotEmpty, IsString } from "class-validator";

export class ChatDTO {
    @ApiProperty({ example: "Nổi mụn bọc sưng đỏ ở mặt và lưng, đau khi chạm vào" })
    @IsString()
    @IsNotEmpty()
    symptoms: string;
}
