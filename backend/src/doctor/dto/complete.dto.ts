import { ApiProperty } from "@nestjs/swagger";
import { ArrayMinSize, ArrayUnique, IsArray, IsInt } from "class-validator";

/** Bác sĩ gửi chẩn đoán: chọn ≥ 1 bệnh/dịch vụ trong bảng giá. */
export class CompleteDTO {
    @ApiProperty({ example: [1, 2], type: [Number] })
    @IsArray()
    @ArrayMinSize(1, { message: "Chọn ít nhất 1 bệnh/dịch vụ" })
    @ArrayUnique()
    @IsInt({ each: true })
    diseaseIds: number[];
}
