import { ApiProperty } from "@nestjs/swagger";
import { IsIn, IsInt, IsNumber, IsOptional, IsString } from "class-validator";

export class PayDTO {
    @ApiProperty({ enum: ["cash", "qr"] })
    @IsIn(["cash", "qr"])
    method: "cash" | "qr";
}

/** SePay webhook body (only the fields we use are validated; the rest are stripped). */
export class SepayWebhookDTO {
    @ApiProperty() @IsInt() id: number;
    @ApiProperty() @IsString() transferType: string; // "in" | "out"
    @ApiProperty() @IsNumber() transferAmount: number;
    @ApiProperty() @IsString() content: string;
    @ApiProperty({ required: false }) @IsOptional() @IsString() gateway?: string;
    @ApiProperty({ required: false }) @IsOptional() @IsString() transactionDate?: string;
    @ApiProperty({ required: false }) @IsOptional() @IsString() accountNumber?: string;
    @ApiProperty({ required: false }) @IsOptional() @IsString() referenceCode?: string;
}
