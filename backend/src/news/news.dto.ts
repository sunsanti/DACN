import { ApiProperty } from "@nestjs/swagger";
import { IsNotEmpty, IsString, IsUrl, MaxLength } from "class-validator";

export class CreateNewsDTO {
    @ApiProperty({ example: "5 cách phòng bệnh da mùa nồm" })
    @IsString()
    @IsNotEmpty()
    @MaxLength(200)
    title: string;

    @ApiProperty({ example: "https://suckhoedoisong.vn/..." })
    @IsUrl({ protocols: ["http", "https"], require_protocol: true }) // chặn javascript:, file:
    @MaxLength(2000)
    url: string;
}
