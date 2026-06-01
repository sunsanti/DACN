import { Body, Controller, Delete, Get, Param, Post, ParseIntPipe } from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { DoctorService } from "./doctor.service";
import { DoctorEntity } from "./entities/doctor.entity";
import { CancelShiftDto } from "./dto/cancelShift.dto";
import { AppointmentEntity } from "src/patient/entities/appointment.entity";
import { ConfirmAppointmentDTO } from "./dto/confirm.dto";
import { ReAppointmentDTO } from "./dto/RA.dto";
import { ShiftListDTO } from "./dto/shiftList.dto";

@Controller('doctor')
@ApiTags('doctor')
export class DoctorController {
    constructor(private readonly doctorService: DoctorService) {};

    @Post('/create-doctor')
    createDoctor(): Promise<DoctorEntity>{
        return this.doctorService.createDoctor();
    }

    @Get('/list-unAcpappointment/:doctorId')
    listUnaccpetAppointment(@Param('doctorId', ParseIntPipe) doctorId: number): Promise<AppointmentEntity[]> {
        return this.doctorService.listUnacceptedAppointment(doctorId);
    }

    @Get('/list-appointment/:doctorId')
    listAcceptAppointment(@Param('doctorId', ParseIntPipe) doctorId: number): Promise<AppointmentEntity[]> {
        return this.doctorService.listAcceptedAppointment(doctorId);
    }

    @Post('/addShift/:id')
    addWorkingTime(
     @Param('id', ParseIntPipe) doctorId: number,
     @Body() body: ShiftListDTO,
    ) {
        return this.doctorService.addWorkingTime(doctorId, body.shifts);
    }

    @Post('/cancel-shift')
    cancelShift(@Body() body: CancelShiftDto): Promise<void> {
        return this.doctorService.cancelShift(body.doctorId, body.shiftId);
    }

    @Post('/reAppointment/:id')
    reAppointment(
        @Param('id', ParseIntPipe) reAppointmentId: number,
        @Body() reAppointmentDto: ReAppointmentDTO
    ): Promise<AppointmentEntity> {
        const { newApTime, newConfirmTime, newNote } = reAppointmentDto;
        return this.doctorService.reAppointment(reAppointmentId, newApTime, newConfirmTime, newNote);
    }

    @Post('/confirm-appointment/:id')
    confirmAppointment(
        @Param('id', ParseIntPipe) appointmentId: number,
        @Body() confirmDto: ConfirmAppointmentDTO
    ): Promise<AppointmentEntity> {
        return this.doctorService.confirmAppointment(appointmentId, confirmDto.note, confirmDto.confirmDate);
    }

    @Delete('/delete-shift/:doctorId/shifts/:shiftId')
    deleteShift(
        @Param('doctorId', ParseIntPipe) doctorId: number,
        @Param('shiftId', ParseIntPipe) shiftId: number
    ) {
        return this.doctorService.deleteShift(doctorId, shiftId);
    }

    @Get('/list-shift/:id')
    listOfShift(@Param('id', ParseIntPipe) doctorId: number){
        return this.doctorService.listOfShifts(doctorId);
    }

    @Get('/list')
    getAllDoctors(): Promise<DoctorEntity[]> {
        return this.doctorService.getAllDoctors();
    }

    @Post('/reject-appointment/:id')
    rejectAppointment(
        @Param('id', ParseIntPipe) appointmentId: number
    ): Promise<AppointmentEntity> {
        return this.doctorService.rejectAppointment(appointmentId);
    }

    @Post('/complete-appointment/:id')
    completeAppointment(
        @Param('id', ParseIntPipe) appointmentId: number
    ): Promise<AppointmentEntity> {
        return this.doctorService.completeAppointment(appointmentId);
    }

    @Post('/missed-appointment/:id')
    missedAppointment(
        @Param('id', ParseIntPipe) appointmentId: number
    ): Promise<AppointmentEntity> {
        return this.doctorService.missedAppointment(appointmentId);
    }

    @Post('/follow-up-appointment/:id')
    scheduleFollowUp(
        @Param('id', ParseIntPipe) appointmentId: number,
        @Body() body: { date: string; time: string; note: string }
    ): Promise<AppointmentEntity> {
        return this.doctorService.scheduleFollowUp(appointmentId, body.date, body.time, body.note);
    }
}