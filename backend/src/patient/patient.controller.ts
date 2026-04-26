import { Controller,Post,Body, Get, Delete, Param, Put } from "@nestjs/common";
import { CreateAppoinmentDTO } from "./dto/create_appointment.dto";
import { PatientService } from "./patient.service";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { Appointment } from "./dto/appointment.dto";
import { PatientEntity } from "./entities/patient.entity";

@ApiTags('patient')
@Controller('patient')
export class PatientController {
    constructor(private readonly patientService: PatientService) {}

    @Post('create-appointment')
    setAppointment(@Body() dto: CreateAppoinmentDTO) {
        return this.patientService.setAppointment(dto);
    }

    @Post('create-patient')
    createPatient(): Promise<PatientEntity> {
        return this.patientService.createPatient();
    }

    @Get('list-appointment')
    @ApiOkResponse({ type: [Appointment] })
    listAppointment(patientId: number){
        return this.patientService.listAppointment(1);
    }

    @Delete('delete-appointment/:id')
    deleteAppointment(@Param('id') id: number){
        return this.patientService.deleteAppointment(id);
    }

    @Put('edit-appointment/:id')
    editAppointment(@Param('id') appointmentId: number){
        return this.patientService.editAppointment(appointmentId);
    }
}