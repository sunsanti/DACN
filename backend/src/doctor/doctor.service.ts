import { ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
import { IDoctorService } from "./interfaces/doctor_service.interface";
import { DoctorEntity } from "./entities/doctor.entity";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { ShiftEntity } from "./entities/shift.entity";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { ShiftAssignmentEntity } from "./entities/shiftAssignment.entity";
import { ShiftDTO } from "./dto/shift.dto";
import { MedicalReportEntity } from "../patient/entities/medical_report.entity";

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
        private shiftAssignmentRepo: Repository<ShiftAssignmentEntity>,

        @InjectRepository(MedicalReportEntity)
        private reportRepo: Repository<MedicalReportEntity>
    ) {}

    listDoctors(): Promise<DoctorEntity[]> {
        return this.doctorRepo.find();
    }

    // ---- shift management (clean API used by the doctor app) ----

    /** Available shift slot templates (morning/afternoon). */
    listShiftTemplates(): Promise<ShiftEntity[]> {
        return this.shiftRepo.find({ order: { startTime: "ASC" } });
    }

    /** Register the logged-in doctor for a shift template -> ACTIVE assignment. */
    async registerShift(doctorId: number, shiftId: number): Promise<ShiftAssignmentEntity> {
        const template = await this.shiftRepo.findOne({ where: { id: shiftId } });
        if (!template) throw new NotFoundException("Mẫu ca trực không tồn tại");
        const start = new Date(template.startTime);
        const end = new Date(template.endTime);
        const duration = Math.max(0, (end.getTime() - start.getTime()) / 3_600_000);
        return this.shiftAssignmentRepo.save({
            doctor: { id: doctorId } as DoctorEntity,
            shift: { id: shiftId } as ShiftEntity,
            type: template.type,
            startTime: start,
            endTime: end,
            status: "ACTIVE",
            duration: Math.round(duration * 100) / 100,
        });
    }

    /** Shift assignments of the logged-in doctor. */
    myShifts(doctorId: number): Promise<ShiftAssignmentEntity[]> {
        return this.shiftAssignmentRepo.find({
            where: { doctor: { id: doctorId } },
            order: { startTime: "DESC" },
        });
    }

    private async assertOwnsAssignment(doctorId: number, assignmentId: number): Promise<ShiftAssignmentEntity> {
        const a = await this.shiftAssignmentRepo.findOne({
            where: { id: assignmentId },
            relations: ["doctor"],
        });
        if (!a) throw new NotFoundException("Không tìm thấy ca trực");
        if (a.doctor?.id !== doctorId) throw new ForbiddenException("Không phải ca của bạn");
        return a;
    }

    /** Cancel an assignment by its id (no longer counts toward salary). */
    async cancelAssignment(doctorId: number, assignmentId: number): Promise<ShiftAssignmentEntity> {
        await this.assertOwnsAssignment(doctorId, assignmentId);
        await this.shiftAssignmentRepo.update(assignmentId, {
            status: "CANCELED",
            endTime: new Date(),
            duration: 0,
        });
        const updated = await this.shiftAssignmentRepo.findOne({ where: { id: assignmentId } });
        if (!updated) throw new NotFoundException("Không tìm thấy ca trực");
        return updated;
    }

    async deleteAssignment(doctorId: number, assignmentId: number): Promise<void> {
        await this.assertOwnsAssignment(doctorId, assignmentId);
        await this.shiftAssignmentRepo.delete(assignmentId);
    }

    /** Latest AI report PDF for an appointment (for the doctor to download). */
    async getReport(appointmentId: number): Promise<Buffer | null> {
        const report = await this.reportRepo.findOne({
            where: { appointment: { id: appointmentId } },
            order: { createdAt: "DESC" },
        });
        return report ? report.pdf : null;
    }

    private async assertOwns(doctorId: number, appointmentId: number): Promise<AppointmentEntity> {
        const appt = await this.appointmentRepo.findOne({
            where: { id: appointmentId },
            relations: ["doctor"],
        });
        if (!appt) throw new NotFoundException("Lịch khám không tồn tại");
        if (appt.doctor?.id !== doctorId) throw new ForbiddenException("Không phải lịch của bạn");
        return appt;
    }

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

    listUnacceptedAppointment(doctorId: number): Promise<AppointmentEntity[]> {
        // confirmCondition 1 = chờ xác nhận (critical-constraints rule 3)
        return this.appointmentRepo.find({
            where: { confirmCondition: 1, doctor: { id: doctorId } },
            relations: ["patient"],
            order: { apTime: "ASC" },
        });
    }

    listAcceptedAppointment(doctorId: number): Promise<AppointmentEntity[]> {
        // confirmCondition 0 = đã xác nhận
        return this.appointmentRepo.find({
            where: { confirmCondition: 0, doctor: { id: doctorId } },
            relations: ["patient"],
            order: { apTime: "ASC" },
        });
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

    // duration (giờ) của ca = endTime - startTime (cột duration là NOT NULL)
    const end = new Date(endTime);
    const duration = Math.max(0, (end.getTime() - now.getTime()) / 3_600_000);

    // 3. luôn CREATE NEW ROW
    const created = await this.shiftAssignmentRepo.save({
      doctor: { id: doctorId },
      shift: { id: shift.shiftId },
      status: 'ACTIVE',
      startTime: now,
      endTime: end,
      type: shift.type,
      duration,
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
        const now = new Date();
        const shift = await this.shiftAssignmentRepo.findOne({
            where: {
                doctor: { id: doctorId },
                shift: { id: shiftId }
            }
        });
        if (!shift) throw new NotFoundException("Không tìm thấy ca trực");

        // Số giờ đã làm tính tới lúc huỷ = now - startTime (thay công thức cũ bị
        // sai thứ tự toán tử: `12 - h + m/60`).
        const worked = Math.max(0, (now.getTime() - new Date(shift.startTime).getTime()) / 3_600_000);

        await this.shiftAssignmentRepo.update(
            { doctor: { id: doctorId }, shift: { id: shiftId } },
            { status: 'CANCELED', endTime: now, duration: Math.round(worked * 100) / 100 }
        );
    }

    async reAppointment(doctorId: number, reAppointmentId: number, newApTime: Date, newConfirmTime: Date, newNote: string): Promise<AppointmentEntity> {
        await this.assertOwns(doctorId, reAppointmentId);
        await this.appointmentRepo.update(
            { id: reAppointmentId },
            { apTime: newApTime, confirmDate: newConfirmTime, note: newNote }
        );
        const reAppointment = await this.appointmentRepo.findOne({
            where: { id: reAppointmentId }
        });
        if (!reAppointment) throw new NotFoundException("Lịch khám không tồn tại");
        return reAppointment;
    }

    async confirmAppointment(doctorId: number, appointmentId: number, note: string, confirmDate: Date): Promise<AppointmentEntity> {
        await this.assertOwns(doctorId, appointmentId);
        await this.appointmentRepo.update(
            { id: appointmentId },
            { note: note, confirmCondition: 0, confirmDate: confirmDate } // 0 = đã xác nhận
        );
        const confirmedAppointment = await this.appointmentRepo.findOne({
            where: { id: appointmentId }
        });
        if (!confirmedAppointment) throw new NotFoundException("Lịch khám không tồn tại");
        return confirmedAppointment;
    }

    //remember to make the payment for the app, with the qr is ok
    calculateTime(): Promise<void> {

        return Promise.resolve();
    }
}