import { Injectable } from "@nestjs/common";
import { IDoctorService } from "./interfaces/doctor_service.interface";
import { Appointment } from "src/patient/interfaces/appointment.interface";
import { Shift } from "./interfaces/shift.interface";
import { DoctorEntity } from "./entities/doctor.entity";
import { InjectRepository } from "@nestjs/typeorm";
import { DeepPartial, Repository } from "typeorm";
import { ShiftEntity } from "./entities/shift.entity";
import { AppointmentEntity } from "src/patient/entities/appointment.entity";
import { ConfirmAppointmentDTO } from "./dto/confirm.dto";

@Injectable()
export class DoctorService implements IDoctorService {
    constructor(
        @InjectRepository(DoctorEntity)
        private doctorRepo: Repository<DoctorEntity>,

        @InjectRepository(ShiftEntity)
        private shiftRepo: Repository<ShiftEntity>,

        @InjectRepository(AppointmentEntity)
        private appointmentRepo: Repository<AppointmentEntity>
    ) {}

    createDoctor(): Promise<DoctorEntity> {
        let newDoctor = {
            name: 'Test3',
            age: 26,
            dateOfBirth: new Date('2000-03-02'),
            gender: 'male',
            phone: '0111111888',
            address: 'dia chi phong kham',
            email: 'testthu3@gmail.com'
        }
        return this.doctorRepo.save(newDoctor)
    }

    listUnacceptedAppointment(): Promise<AppointmentEntity[]> {
        let confirmCondition = 1;
        //show all the appointments with 0 condition in database

        return this.appointmentRepo.find({
            where: {confirmCondition: 1}
        })
    }

    listAcceptedAppointment(): Promise<AppointmentEntity[]> {
        let confirmCondition = '1';
        //show all the appointments with 1 condition
        return this.appointmentRepo.find({
            where: {confirmCondition: 0}
        })
    }

    // đối với cái này sẽ làm cái struct ở ngoại để tính tổng thời lượng cho tiện, còn việc đăng kí shift cụ thể thì để làm function rồi đẩy nó lên luôn
    //nhớ lưu db riêng là weeks nữa để tính tổng số giờ làm á\
    //check if that day there is anyone cancel the shift first
    async addWorkingTime(): Promise<DoctorEntity> {
        // const Schedule = {
        //     workingSchedule: Number, //total number of shifts
        //     workingTime: Number, //total working time (hours)
        //     daySchedule: Date, //this shift will have 5 hours
        //     afternoonSchedule: Date, // this shift will have 6 hours
        //     emergency: Number // 0 means having, 1 means no
        // }
        /*
        đánh dấu lịch là từ 1 đến nhiu đó
         * nếu không chia hết cho 2 thì sẽ là morning (điền các thông tin cơ bản vào)
         * nếu chia hết thfi điền afternoon  
         */
        const shifts = await this.shiftRepo.save([
            {
                type: 'morning',
                startTime: new Date('2025-04-28'),
                endTime: new Date('2026-04-29'),
                emergency: 1
            },
            {
                type: 'afternoon',
                startTime: new Date('2026-04-28'),
                endTime: new Date('2026-04-29'),
                emergency: 1
            }
        ])
        return this.doctorRepo.save({
            id: 1,
            shifts: shifts
        })
        // nhớ là sẽ kiểm tra xem có emergency đồ k để làm
    }


    async cancelShift(doctorId: number, shiftId: number): Promise<void> {
        // let emergency = 1

        // const now = new Date();

        // const hour = now.getHours();
        // const minute = now.getMinutes();

        // let shift: number = 1;
        // if(shift = 1){
        //     const hourLeft = 12 - (hour + minute/60);
        // } else {
        //     const hourLeft = 8.5 - (hour + minute/60);
        // }

        // const hourWorked = hour + minute/60;
        // // give the hourWorked into the db
        // // give the hourLeft to the one who work

        // return Promise.resolve();


        const listShifts = await this.doctorRepo.findOne({
            where: {
                id: doctorId,
                shifts: {
                    id: shiftId,
                }
            },
            relations: ['shifts']
        });

        if(!listShifts) return
        await this.shiftRepo.update(shiftId, {emergency: 0});
        //doanj nay chua test
        // const type = listShifts.shifts[0].type;
        // const time = listShifts.shifts[0].startTime;
        // const morningBegin = 
        // if(type === 'morning' && ){
        //     const hourLeft = 12 - 
        // }
        

    }

    async reAppointment(reAppointmentId: number, newApTime: Date, newConfirmTime: Date, newNote: string): Promise<AppointmentEntity> {
        const newAppointment = await this.appointmentRepo.update(
            {id: reAppointmentId},
            { apTime: newApTime, confirmDate: newConfirmTime, note: newNote }
        )
        const reAppointment = await this.appointmentRepo.findOne({
            where: { id: reAppointmentId }
        })
        if(!reAppointment) return Promise.resolve({} as AppointmentEntity);
        //take the appointment with the id, and edit the new appointment
        return reAppointment;
    }

    async confirmAppointment(appointmentId: number, note: string, confirmDate: Date): Promise<AppointmentEntity> {
        const updateAppointment = await this.appointmentRepo.update(
            {id: appointmentId},
            { note: note, confirmCondition: 0, confirmDate: confirmDate}
        )
        const confirmedAppointment = await this.appointmentRepo.findOne({
            where: { id: appointmentId }
        })

        if(!confirmedAppointment) return Promise.resolve({} as AppointmentEntity);

        return confirmedAppointment;

        
        
    }

    //remember to make the payment for the app, with the qr is ok
    calculateTime(): Promise<void> {

        return Promise.resolve();
    }
}