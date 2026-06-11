import { ApiProperty } from "@nestjs/swagger";
import { IsNotEmpty, IsString } from "class-validator";

export class CancelDTO {
    @ApiProperty({ example: "Bận đột xuất, không đến khám được" })
    @IsString()
    @IsNotEmpty()
    reason: string;
}
