import { Controller, Post, Body, Get, Delete, Param, Put, ParseIntPipe } from "@nestjs/common";
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";
import { PatientService } from "./patient.service";
import { ApiBearerAuth, ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { Appointment } from "./dto/appointment.dto";
import { Roles } from "../common/decorators/roles.decorator";
import { CurrentUser } from "../common/decorators/current-user.decorator";
import type { JwtPayload } from "../auth/jwt-payload.interface";

@ApiTags('patient')
@ApiBearerAuth()
@Roles('patient')
@Controller('patient')
export class PatientController {
    constructor(private readonly patientService: PatientService) {}

    @Post('create-appointment')
    setAppointment(@CurrentUser() user: JwtPayload, @Body() dto: CreateAppoinmentDTO) {
        return this.patientService.setAppointment(user.patientId!, dto);
    }

    @Get('list-appointment')
    @ApiOkResponse({ type: [Appointment] })
    listAppointment(@CurrentUser() user: JwtPayload) {
        return this.patientService.listAppointment(user.patientId!);
    }

    @Delete('delete-appointment/:id')
    deleteAppointment(@Param('id', ParseIntPipe) id: number) {
        return this.patientService.deleteAppointment(id);
    }

    @Put('edit-appointment/:id')
    editAppointment(@Param('id', ParseIntPipe) appointmentId: number) {
        return this.patientService.editAppointment(appointmentId);
    }
}
