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

    // 🌟 ĐÃ SỬA: confirmCondition = 0 (Lịch hẹn MỚI/CHỜ DUYỆT)
    async listUnacceptedAppointment(doctorId: number): Promise<AppointmentEntity[]> {
        return await this.appointmentRepo.find({
            where: {
                confirmCondition: 0, // 0 là chờ duyệt
                doctor: { id: doctorId }
            },
            relations: ['patient'] 
        });
    }

    // 🌟 ĐÃ SỬA: confirmCondition = 1 (Lịch hẹn ĐÃ ĐƯỢC DUYỆT)
    async listAcceptedAppointment(doctorId: number): Promise<AppointmentEntity[]> {
        return await this.appointmentRepo.find({
            where: {
                confirmCondition: 1, // 1 là đã duyệt
                doctor: { id: doctorId } 
            },
            relations: ['patient'] 
        });
    }

    async listOfShifts(doctorId: number): Promise<ShiftAssignmentEntity[]> {
        const shift = await this.shiftAssignmentRepo.find({
            where: {doctor: {
                id: doctorId,
            }}
        });

        if(!shift) return []

        return shift;
    }

    async addWorkingTime(
      doctorId: number,
      shifts: ShiftDTO[]
    ): Promise<ShiftAssignmentEntity[]> {

      const now = new Date();
      const results: ShiftAssignmentEntity[] = [];

      for (const shift of shifts) {
        const canceled = await this.shiftAssignmentRepo.findOne({
          where: {
            shift: { id: shift.shiftId },
            status: 'CANCELED'
          }
        });

        let endTime = shift.endTime;

        if (canceled) {
          endTime = canceled.endTime;
        }

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
        return reAppointment;
    }

    // 🌟 ĐÃ SỬA: Khi bác sĩ nhấn nút duyệt, cập nhật trạng thái thành 1
    async confirmAppointment(appointmentId: number, note: string, confirmDate: Date): Promise<AppointmentEntity> {
        const updateAppointment = await this.appointmentRepo.update(
            {id: appointmentId},
            { note: note, confirmCondition: 1, confirmDate: confirmDate} // Chuyển từ 0 thành 1
        )
        const confirmedAppointment = await this.appointmentRepo.findOne({
            where: { id: appointmentId }
        })

        if(!confirmedAppointment) return Promise.resolve({} as AppointmentEntity);
        return confirmedAppointment;
    }

    calculateTime(): Promise<void> {
        return Promise.resolve();
    }

    async getAllDoctors(): Promise<DoctorEntity[]> {
        return await this.doctorRepo.find(); 
    }
}