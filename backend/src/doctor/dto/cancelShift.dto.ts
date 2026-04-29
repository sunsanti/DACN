import { ApiProperty } from '@nestjs/swagger';

export class CancelShiftDto {
  @ApiProperty()
  doctorId: number;

  @ApiProperty()
  shiftId: number;
}