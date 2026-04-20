import { Controller, Get, Post } from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { DoctorService } from "./doctor.service";
import { Appointment } from "src/patient/interfaces/appointment.interface";
import { Shift } from "./interfaces/shift.interface";

@Controller('doctor')
@ApiTags('doctor')
export class DoctorController{
    constructor(private readonly doctorService: DoctorService) {};

    @Get('/list-unAcpappointment')
    listUnaccpetAppointment(): Promise<Appointment[]> {
        return this.doctorService.listUnacceptedAppointment();
    }

    @Get('/list-appointment')
    listAcceptAppointment(): Promise<Appointment[]> {
        return this.doctorService.listAcceptedAppointment();
    }

    @Post('/addShift')
    addWorkingTime(): Promise<Shift[]> {
        let shifts: Shift[] = [
            {
                id: 1,
                doctorId: 1,
                type: 'morning',
                startTime: new Date('2025-08-10'),
                endTime: new Date('2025-08-10'),
                emergency: 0
            },
            {
                id: 2,
                doctorId: 1,
                type: 'morning',
                startTime: new Date('2025-08-10'),
                endTime: new Date('2025-08-10'),
                emergency: 0
            }
        ];
        return Promise.resolve(shifts);
    }

    @Post('/cancel-shift')
    cancelShift(): Promise<void> {
        /*
        shift option A
        This is uesed to return the value for the admin
        it will return the time of the employee has done
         */
        return Promise.resolve();
    }

    @Post('/reAppointment')
    reAppointment(): Promise<Appointment> {
        let newAppTime = new Date('2026-04-30');
        let newConfirmDate = new Date('2026-05-01');
        let newNote = 'Tai Kham';
        let reAppointment: Appointment = {
            id: 3,
            apTime: newAppTime,
            confirmDate: newConfirmDate,
            address: 'abc',
            note: newNote,
            confirmCondition: 0,
            doctor: 'Quan',
            patientId: 1,
            doctorId: 1
        }
        return Promise.resolve(reAppointment);
    }

    @Post('/confirm-appointmnet')
    confirmAppointment(): Promise<Appointment> {
        let confirmDate = new Date('2026-10-1');
        let note: string = 'day la de note';
        let confirmCondition: number = 0;

        //create new appointment with these informations
        return Promise.resolve({} as Appointment);
    }

}