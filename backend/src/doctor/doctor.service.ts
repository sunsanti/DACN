import { Injectable } from "@nestjs/common";
import { IDoctorService } from "./interfaces/doctor_service.interface";
import { Appointment } from "src/patient/interfaces/appointment.interface";
import { Shift } from "./interfaces/shift.interface";
import { DoctorEntity } from "./entities/doctor.entity";
import { InjectRepository } from "@nestjs/typeorm";
import { DeepPartial, Repository } from "typeorm";
import { ShiftEntity } from "./entities/shift.entity";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { ConfirmAppointmentDTO } from "./dto/confirm.dto";
import { ShiftAssignmentEntity } from "./entities/shiftAssignment.entity";
import { timeEnd } from "console";
import { ShiftDTO } from "./dto/shift.dto";

@Injectable()
export class DoctorService implements IDoctorService {
    constructor(
        @InjectRepository(DoctorEntity)
        private doctorRepo: Repository<DoctorEntity>,

        @InjectRepository(ShiftEntity)
        private shiftRepo: Repository<ShiftEntity>,

        @InjectRepository(AppointmentEntity)
        private appointmentRepo: Repository<AppointmentEntity>,

        @InjectRepository(ShiftAssignmentEntity)
        private shiftAssignmentRepo: Repository<ShiftAssignmentEntity>
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

    async listOfShifts(doctorId: number): Promise<ShiftAssignmentEntity[]> {
        // const doctor = await this.doctorRepo.findOne({
        //     where: {id: doctorId},
        //     relations: ['shifts']
        // })
        
        // if(!doctor) return Promise.resolve({} as ShiftEntity[])

        // return doctor.shifts;
        const shift = await this.shiftAssignmentRepo.find({
            where: {doctor: {
                id: doctorId,
            }}
        });

        if(!shift) return []

        return shift;
    }

    // đối với cái này sẽ làm cái struct ở ngoại để tính tổng thời lượng cho tiện, còn việc đăng kí shift cụ thể thì để làm function rồi đẩy nó lên luôn
    //nhớ lưu db riêng là weeks nữa để tính tổng số giờ làm á\
    //check if that day there is anyone cancel the shift first
async addWorkingTime(
  doctorId: number,
  shifts: ShiftDTO[]
): Promise<ShiftAssignmentEntity[]> {

  const now = new Date();
  const results: ShiftAssignmentEntity[] = [];

  for (const shift of shifts) {

    // 1. tìm record canceled
    const canceled = await this.shiftAssignmentRepo.findOne({
      where: {
        shift: { id: shift.shiftId },
        status: 'CANCELED'
      }
    });

    let endTime = shift.endTime;

    // 2. nếu có canceled → lấy endTime từ canceled
    if (canceled) {
      endTime = canceled.endTime;
    }

    // 3. luôn CREATE NEW ROW
    const created = await this.shiftAssignmentRepo.save({
      doctor: { id: doctorId },
      shift: { id: shift.shiftId },
      status: 'ACTIVE',
      startTime: now,
      endTime: endTime,
      type: shift.type
    });

    results.push(created);
  }

  return results;
}

    async deleteShift(doctorId: number, shiftId: number): Promise<void> {
        // const doctorShift = await this.doctorRepo.findOne({
        //     where: {
        //         id: doctorId,
        //     },
        //     relations: ['shifts']
        // })

        // const shift = doctorShift?.shifts.find(s => s.id === shiftId);
        // await this.doctorRepo
        //     .createQueryBuilder()
        //     .relation('shifts')
        //     .of(doctorId)
        //     .remove(shiftId)
        
        // await this.shiftRepo.delete(shiftId);
        // return Promise.resolve({} as DoctorEntity);
        const deleteShift = await this.shiftAssignmentRepo.delete({
            doctor: { id: doctorId },
            shift: { id: shiftId }
        })
    }

    async cancelShift(doctorId: number, shiftId: number): Promise<void> {
        const time = new Date();
        const shift = await this.shiftAssignmentRepo.findOne({
            where: {
                doctor: { id: doctorId },
                shift: { id: shiftId }
            }
        })
        if(shift?.type == 'morning'){
            const updateStatus = await this.shiftAssignmentRepo.update(
            {
                doctor: { id: doctorId },
                shift: { id: shiftId }
            },
            {
                status: 'CANCELED',
                endTime: new Date(),
                duration: 12 - time.getHours() + time.getMinutes()/60
            }
        )
        } else {
            const updateStatus = await this.shiftAssignmentRepo.update(
            {
                doctor: { id: doctorId },
                shift: { id: shiftId }
            },
            {
                status: 'CANCELED',
                endTime: new Date(),
                duration: 20 - time.getHours() + time.getMinutes()/60
            }
        )
        }
        

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