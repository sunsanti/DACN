import { Controller, Post, Body, Get, Delete, Param, Put, ParseIntPipe } from "@nestjs/common";
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";
import { UpdateAppointmentDTO } from "./dto/update_appointment.dto";
import { UpdatePatientDTO } from "./dto/update_patient.dto";
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

    @Get('me')
    getProfile(@CurrentUser() user: JwtPayload) {
        return this.patientService.getProfile(user.patientId!);
    }

    @Put('me')
    updateProfile(@CurrentUser() user: JwtPayload, @Body() dto: UpdatePatientDTO) {
        return this.patientService.updateProfile(user.patientId!, dto);
    }

    @Post('create-appointment')
    setAppointment(@CurrentUser() user: JwtPayload, @Body() dto: CreateAppoinmentDTO) {
        return this.patientService.setAppointment(user.patientId!, dto);
    }

    @Get('list-appointment')
    @ApiOkResponse({ type: [Appointment] })
    listAppointment(@CurrentUser() user: JwtPayload) {
        return this.patientService.listAppointment(user.patientId!);
    }

    @Get('appointment/:id')
    getAppointment(@CurrentUser() user: JwtPayload, @Param('id', ParseIntPipe) id: number) {
        return this.patientService.getAppointment(user.patientId!, id);
    }

    @Delete('delete-appointment/:id')
    deleteAppointment(@CurrentUser() user: JwtPayload, @Param('id', ParseIntPipe) id: number) {
        return this.patientService.deleteAppointment(user.patientId!, id);
    }

    @Put('edit-appointment/:id')
    editAppointment(
        @CurrentUser() user: JwtPayload,
        @Param('id', ParseIntPipe) appointmentId: number,
        @Body() dto: UpdateAppointmentDTO,
    ) {
        return this.patientService.editAppointment(user.patientId!, appointmentId, dto);
    }
}
