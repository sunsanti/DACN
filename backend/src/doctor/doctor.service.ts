import { Injectable, NotFoundException } from "@nestjs/common";
import { IDoctorService } from "./interfaces/doctor_service.interface";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository, In } from "typeorm";
import { DoctorEntity } from "./entities/doctor.entity";
import { ShiftEntity } from "./entities/shift.entity";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { ShiftAssignmentEntity } from "./entities/shiftAssignment.entity";
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

    // 🌟 ĐÃ CẬP NHẬT: Đảm bảo TypeORM bốc toàn bộ các cột (bao gồm cả cột chứa link PDF)
    async listUnacceptedAppointment(doctorId: number): Promise<AppointmentEntity[]> {
        return await this.appointmentRepo.find({
            where: {
                confirmCondition: 0,
                doctor: { id: doctorId }
            },
            relations: ['patient'] 
        });
    }

    async listAcceptedAppointment(doctorId: number): Promise<AppointmentEntity[]> {
        return await this.appointmentRepo.find({
            where: {
                confirmCondition: In([1, 2, 4]), 
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

    async addWorkingTime(doctorId: number, shifts: ShiftDTO[]): Promise<ShiftAssignmentEntity[]> {
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
        await this.shiftAssignmentRepo.delete({
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
            await this.shiftAssignmentRepo.update(
            {
                doctor: { id: doctorId },
                shift: { id: shiftId }
            },
            {
                status: 'CANCELED',
                endTime: new Date(),
                duration: 12 - time.getHours() + time.getMinutes()/60
            })
        } else {
            await this.shiftAssignmentRepo.update(
            {
                doctor: { id: doctorId },
                shift: { id: shiftId }
            },
            {
                status: 'CANCELED',
                endTime: new Date(),
                duration: 20 - time.getHours() + time.getMinutes()/60
            })
        }
    }

    async reAppointment(reAppointmentId: number, newApTime: Date, newConfirmTime: Date, newNote: string): Promise<AppointmentEntity> {
        await this.appointmentRepo.update(
            {id: reAppointmentId},
            { apTime: newApTime, confirmDate: newConfirmTime, note: newNote }
        )
        const reAppointment = await this.appointmentRepo.findOne({
            where: { id: reAppointmentId }
        })
        if(!reAppointment) return Promise.resolve({} as AppointmentEntity);
        return reAppointment;
    }

    async confirmAppointment(appointmentId: number, note: string, confirmDate: Date): Promise<AppointmentEntity> {
        await this.appointmentRepo.update(
            {id: appointmentId},
            { note: note, confirmCondition: 1, confirmDate: confirmDate} 
        )
        const confirmedAppointment = await this.appointmentRepo.findOne({
            where: { id: appointmentId }
        })
        if(!confirmedAppointment) return Promise.resolve({} as AppointmentEntity);
        return confirmedAppointment;
    }

    async rejectAppointment(appointmentId: number): Promise<AppointmentEntity> {
        await this.appointmentRepo.update(
            { id: appointmentId },
            { confirmCondition: -1 } 
        );
        const rejectedAppointment = await this.appointmentRepo.findOne({
            where: { id: appointmentId }
        });
        if(!rejectedAppointment) return Promise.resolve({} as AppointmentEntity);
        return rejectedAppointment;
    }

    async completeAppointment(appointmentId: number): Promise<AppointmentEntity> {
        await this.appointmentRepo.update(
            { id: appointmentId },
            { confirmCondition: 2 } 
        );
        const completedAppointment = await this.appointmentRepo.findOne({
            where: { id: appointmentId }
        });
        if(!completedAppointment) return Promise.resolve({} as AppointmentEntity);
        return completedAppointment;
    }

    async missedAppointment(appointmentId: number): Promise<AppointmentEntity> {
        await this.appointmentRepo.update(
            { id: appointmentId },
            { confirmCondition: 3 } 
        );
        const missedAppt = await this.appointmentRepo.findOne({
            where: { id: appointmentId }
        });
        if(!missedAppt) return Promise.resolve({} as AppointmentEntity);
        return missedAppt;
    }

    calculateTime(): Promise<void> {
        return Promise.resolve();
    }

    async getAllDoctors(): Promise<DoctorEntity[]> {
        return await this.doctorRepo.find(); 
    }

    async scheduleFollowUp(id: number, date: string, time: string, note: string): Promise<AppointmentEntity> {
        const appointment = await this.appointmentRepo.findOne({ where: { id } });
        if (!appointment) {
            throw new NotFoundException('Không tìm thấy lịch hẹn để hẹn tái khám!');
        }
        const combinedDateTime = new Date(`${date}T${time}:00`);
        appointment.confirmCondition = 4; 
        appointment.apTime = combinedDateTime; 
        appointment.note = note; 
        return await this.appointmentRepo.save(appointment);
    }
}