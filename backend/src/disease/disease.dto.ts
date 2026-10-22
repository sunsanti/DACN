import { ApiProperty, PartialType } from "@nestjs/swagger";
import { IsBoolean, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from "class-validator";

export class CreateDiseaseDTO {
    @ApiProperty({ example: "Viêm da cơ địa" })
    @IsString()
    @IsNotEmpty()
    @MaxLength(200)
    name: string;

    @ApiProperty({ example: 50000, description: "VND" })
    @IsInt()
    @Min(0)
    price: number;

    @ApiProperty({ required: false, default: true, description: "Được BHYT chi trả" })
    @IsOptional()
    @IsBoolean()
    bhytCovered?: boolean;
}

export class UpdateDiseaseDTO extends PartialType(CreateDiseaseDTO) {
    @ApiProperty({ required: false })
    @IsOptional()
    @IsBoolean()
    active?: boolean;
}
