import { ApiProperty } from "@nestjs/swagger";
import { ShiftDTO } from "./shift.dto";

export class ShiftListDTO {
  @ApiProperty({ type: [ShiftDTO] })
  shifts: ShiftDTO[];
} 