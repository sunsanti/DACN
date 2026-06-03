import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    ParseIntPipe,
    Post,
    Res,
    NotFoundException,
} from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import type { Response } from "express";
import { DoctorService } from "./doctor.service";
import { DoctorEntity } from "./entities/doctor.entity";
import { CancelShiftDto } from "./dto/cancelShift.dto";
import { AppointmentEntity } from "src/patient/entities/appointment.entity";
import { ConfirmAppointmentDTO } from "./dto/confirm.dto";
import { ReAppointmentDTO } from "./dto/RA.dto";
import { ShiftListDTO } from "./dto/shiftList.dto";
import { UpdateDoctorDTO } from "./dto/update-doctor.dto";
import { ReExaminationDTO } from "./dto/reExamination.dto";
import { RegisterShiftDTO } from "./dto/registerShift.dto";
import { Put, Query } from "@nestjs/common";
import { Roles } from "../common/decorators/roles.decorator";
import { CurrentUser } from "../common/decorators/current-user.decorator";
import type { JwtPayload } from "../auth/jwt-payload.interface";

@Controller('doctor')
@ApiTags('doctor')
@ApiBearerAuth()
export class DoctorController {
    constructor(private readonly doctorService: DoctorService) {}

    // --- open to any authenticated user (patient booking needs the list) ---

    @Post('/create-doctor')
    createDoctor(): Promise<DoctorEntity> {
        return this.doctorService.createDoctor();
    }

    @Get('/list')
    listDoctors(): Promise<DoctorEntity[]> {
        return this.doctorService.listDoctors();
    }

    // ---- admin: view / edit a doctor ----

    @Roles('admin')
    @Get('/detail/:id')
    getDoctor(@Param('id', ParseIntPipe) id: number) {
        return this.doctorService.getDoctor(id);
    }

    @Roles('admin')
    @Put('/update/:id')
    updateDoctor(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateDoctorDTO) {
        return this.doctorService.updateDoctor(id, dto);
    }

    // --- doctor-only: appointments assigned to the logged-in doctor ---

    @Roles('doctor')
    @Get('/list-unAcpappointment')
    listUnaccpetAppointment(@CurrentUser() user: JwtPayload): Promise<AppointmentEntity[]> {
        return this.doctorService.listUnacceptedAppointment(user.doctorId!);
    }

    @Roles('doctor')
    @Get('/list-appointment')
    listAcceptAppointment(@CurrentUser() user: JwtPayload): Promise<AppointmentEntity[]> {
        return this.doctorService.listAcceptedAppointment(user.doctorId!);
    }

    @Roles('doctor')
    @Get('/list-completed')
    listCompleted(@CurrentUser() user: JwtPayload): Promise<AppointmentEntity[]> {
        return this.doctorService.listCompletedAppointment(user.doctorId!);
    }

    @Roles('doctor')
    @Get('/appointment/:id')
    appointmentDetail(@CurrentUser() user: JwtPayload, @Param('id', ParseIntPipe) id: number) {
        return this.doctorService.getAppointmentDetail(user.doctorId!, id);
    }

    @Roles('doctor')
    @Post('/complete/:id')
    completeAppointment(@CurrentUser() user: JwtPayload, @Param('id', ParseIntPipe) id: number) {
        return this.doctorService.completeAppointment(user.doctorId!, id);
    }

    @Roles('doctor')
    @Post('/re-examination')
    reExamination(@CurrentUser() user: JwtPayload, @Body() dto: ReExaminationDTO) {
        return this.doctorService.reExamination(
            user.doctorId!, dto.patientId, dto.apTime, dto.address, dto.note ?? null);
    }

    @Roles('doctor')
    @Post('/confirm-appointment/:id')
    confirmAppointment(
        @CurrentUser() user: JwtPayload,
        @Param('id', ParseIntPipe) appointmentId: number,
        @Body() confirmDto: ConfirmAppointmentDTO,
    ): Promise<AppointmentEntity> {
        return this.doctorService.confirmAppointment(
            user.doctorId!, appointmentId, confirmDto.note, confirmDto.confirmDate);
    }

    @Roles('doctor')
    @Post('/reAppointment/:id')
    reAppointment(
        @CurrentUser() user: JwtPayload,
        @Param('id', ParseIntPipe) reAppointmentId: number,
        @Body() reAppointmentDto: ReAppointmentDTO,
    ): Promise<AppointmentEntity> {
        const { newApTime, newConfirmTime, newNote } = reAppointmentDto;
        return this.doctorService.reAppointment(
            user.doctorId!, reAppointmentId, newApTime, newConfirmTime, newNote);
    }

    @Roles('doctor')
    @Delete('/appointment/:id')
    deleteAppointment(@CurrentUser() user: JwtPayload, @Param('id', ParseIntPipe) id: number) {
        return this.doctorService.deleteAppointment(user.doctorId!, id);
    }

    /** Download the AI report PDF a patient generated for an appointment. */
    @Roles('doctor')
    @Get('/report/:appointmentId')
    async getReport(
        @Param('appointmentId', ParseIntPipe) appointmentId: number,
        @Res() res: Response,
    ) {
        const pdf = await this.doctorService.getReport(appointmentId);
        if (!pdf) throw new NotFoundException('Chưa có báo cáo AI cho lịch này');
        res.set({
            'Content-Type': 'application/pdf',
            'Content-Disposition': `attachment; filename="report-${appointmentId}.pdf"`,
            'Content-Length': pdf.length.toString(),
        });
        res.end(pdf);
    }

    // --- doctor-only: shift management (doctorId from the token) ---

    @Roles('doctor')
    @Post('/addShift')
    addWorkingTime(@CurrentUser() user: JwtPayload, @Body() body: ShiftListDTO) {
        return this.doctorService.addWorkingTime(user.doctorId!, body.shifts);
    }

    @Roles('doctor')
    @Get('/list-shift')
    listOfShift(@CurrentUser() user: JwtPayload) {
        return this.doctorService.listOfShifts(user.doctorId!);
    }

    // ---- clean shift API used by the doctor app ----

    @Roles('doctor')
    @Get('/shift-templates')
    shiftTemplates() {
        return this.doctorService.listShiftTemplates();
    }

    @Roles('doctor')
    @Get('/my-shifts')
    myShifts(@CurrentUser() user: JwtPayload) {
        return this.doctorService.myShifts(user.doctorId!);
    }

    /** Overview of all registered shifts (which doctor works which window). */
    @Roles('doctor', 'admin')
    @Get('/shift-overview')
    shiftOverview() {
        return this.doctorService.shiftOverview();
    }

    /** Free 30-min slots of a doctor on a date (open to any authenticated user for booking). */
    @Get('/availability')
    availability(
        @Query('doctorId', ParseIntPipe) doctorId: number,
        @Query('date') date: string,
    ) {
        return this.doctorService.availability(doctorId, date);
    }

    @Roles('doctor')
    @Post('/register-shift')
    registerShift(@CurrentUser() user: JwtPayload, @Body() dto: RegisterShiftDTO) {
        return this.doctorService.registerShift(user.doctorId!, dto.shiftId, dto.date);
    }

    @Roles('doctor')
    @Post('/cancel-assignment/:id')
    cancelAssignment(@CurrentUser() user: JwtPayload, @Param('id', ParseIntPipe) id: number) {
        return this.doctorService.cancelAssignment(user.doctorId!, id);
    }

    @Roles('doctor')
    @Delete('/assignment/:id')
    deleteAssignment(@CurrentUser() user: JwtPayload, @Param('id', ParseIntPipe) id: number) {
        return this.doctorService.deleteAssignment(user.doctorId!, id);
    }

    @Roles('doctor')
    @Post('/cancel-shift')
    cancelShift(@CurrentUser() user: JwtPayload, @Body() body: CancelShiftDto): Promise<void> {
        return this.doctorService.cancelShift(user.doctorId!, body.shiftId);
    }

    @Roles('doctor')
    @Delete('/delete-shift/:shiftId')
    deleteShift(
        @CurrentUser() user: JwtPayload,
        @Param('shiftId', ParseIntPipe) shiftId: number,
    ) {
        return this.doctorService.deleteShift(user.doctorId!, shiftId);
    }
}
