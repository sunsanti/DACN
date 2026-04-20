import { Injectable } from "@nestjs/common";
import { IDoctorService } from "./interfaces/doctor_service.interface";
import { Appointment } from "src/patient/interfaces/appointment.interface";
import { Shift } from "./interfaces/shift.interface";

@Injectable()
export class DoctorService implements IDoctorService {

    listUnacceptedAppointment(): Promise<Appointment[]> {
        let confirmCondition = '0';
        //show all the appointments with 0 condition in database
        return Promise.resolve({} as Appointment[]);
    }

    listAcceptedAppointment(): Promise<Appointment[]> {
        let confirmCondition = '1';
        //show all the appointments with 1 condition
        return Promise.resolve({} as Appointment[]);
    }

    // đối với cái này sẽ làm cái struct ở ngoại để tính tổng thời lượng cho tiện, còn việc đăng kí shift cụ thể thì để làm function rồi đẩy nó lên luôn
    //nhớ lưu db riêng là weeks nữa để tính tổng số giờ làm á\
    //check if that day there is anyone cancel the shift first
    addWorkingTime(): Promise<Shift[]> {
        const Schedule = {
            workingSchedule: Number, //total number of shifts
            workingTime: Number, //total working time (hours)
            daySchedule: Date, //this shift will have 5 hours
            afternoonSchedule: Date, // this shift will have 6 hours
            emergency: Number // 0 means having, 1 means no
        }
        return Promise.resolve({} as Shift[]);
    }

    // cancelAppointment(appointment: Appointment): Promise<void> {
        
    //     return Promise.resolve();
    // }

    cancelShift(): Promise<void> {
        let emergency = 1

        const now = new Date();

        const hour = now.getHours();
        const minute = now.getMinutes();

        let shift: number = 1;
        if(shift = 1){
            const hourLeft = 12 - (hour + minute/60);
        } else {
            const hourLeft = 8.5 - (hour + minute/60);
        }

        const hourWorked = hour + minute/60;
        // give the hourWorked into the db
        // give the hourLeft to the one who work

        return Promise.resolve();
    }

    reAppointment(appointmentId: number): Promise<Appointment> {
        let newAppTime = new Date();
        let confirmDate = new Date();
        let newNote: string;
        //take the appointment with the id, and edit the new appointment
        return Promise.resolve({} as Appointment);
    }

    confirmAppointment(): Promise<Appointment> {
        let confirmCondition = '1'
        let confirmDate: Date;
        let note: string;
        return Promise.resolve({} as Appointment)
    }

    //remember to make the payment for the app, with the qr is ok
}