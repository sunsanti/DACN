import { Body, Controller, Get, Param, Post } from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { DoctorService } from "./doctor.service";
import { Appointment } from "src/patient/interfaces/appointment.interface";
import { Shift } from "./interfaces/shift.interface";
import { DoctorEntity } from "./entities/doctor.entity";
import { CancelShiftDto } from "./dto/cancelShift.dto";
import { AppointmentEntity } from "src/patient/entities/appointment.entity";
import { ConfirmAppointmentDTO } from "./dto/confirm.dto";
import { ReAppointmentDTO } from "./dto/RA.dto";

@Controller('doctor')
@ApiTags('doctor')
export class DoctorController{
    constructor(private readonly doctorService: DoctorService) {};

    @Post('/create-doctor')
    createDoctor(): Promise<DoctorEntity>{
        return this.doctorService.createDoctor();
    }

    @Get('/list-unAcpappointment')
    listUnaccpetAppointment(): Promise<AppointmentEntity[]> {
        return this.doctorService.listUnacceptedAppointment();
    }

    @Get('/list-appointment')
    listAcceptAppointment(): Promise<AppointmentEntity[]> {
        return this.doctorService.listAcceptedAppointment();
    }

    @Post('/addShift')
    addWorkingTime(): Promise<DoctorEntity> {
        return this.doctorService.addWorkingTime();
    }

    @Post('/cancel-shift')
    cancelShift(@Body() body: CancelShiftDto): Promise<void> {
        const { doctorId, shiftId } = body;
        return this.doctorService.cancelShift(body.doctorId, body.shiftId);
    }

    @Post('/reAppointment/:id')
    reAppointment(@Param('id') reAppointmentId: number,@Body() reAppointmentDto: ReAppointmentDTO): Promise<AppointmentEntity> {
        const { newApTime, newConfirmTime, newNote } = reAppointmentDto;
        return this.doctorService.reAppointment(reAppointmentId, newApTime, newConfirmTime, newNote);
    }

    @Post('/confirm-appointmnet/:id')
    confirmAppointment(@Param('id') appointmentId: number,@Body() confirmDto: ConfirmAppointmentDTO): Promise<AppointmentEntity> {
        const {note, confirmDate} = confirmDto;
        //create new appointment with these informations
        return this.doctorService.confirmAppointment(appointmentId, confirmDto.note, confirmDto.confirmDate)
    }

}