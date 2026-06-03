import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
import { IDoctorService } from "./interfaces/doctor_service.interface";
import { DoctorEntity } from "./entities/doctor.entity";
import { InjectRepository } from "@nestjs/typeorm";
import { Between, IsNull, Repository } from "typeorm";
import { ShiftEntity } from "./entities/shift.entity";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { PatientEntity } from "../patient/entities/patient.entity";
import { ShiftAssignmentEntity } from "./entities/shiftAssignment.entity";
import { ShiftDTO } from "./dto/shift.dto";
import { UpdateDoctorDTO } from "./dto/update-doctor.dto";
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

    async getDoctor(id: number): Promise<DoctorEntity> {
        const doctor = await this.doctorRepo.findOne({ where: { id } });
        if (!doctor) throw new NotFoundException("Bác sĩ không tồn tại");
        return doctor;
    }

    async updateDoctor(id: number, dto: UpdateDoctorDTO): Promise<DoctorEntity> {
        const doctor = await this.getDoctor(id);
        Object.assign(doctor, {
            ...dto,
            dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : doctor.dateOfBirth,
        });
        return this.doctorRepo.save(doctor);
    }

    // ---- shift management (clean API used by the doctor app) ----

    /** Available shift slot templates (morning/afternoon). */
    listShiftTemplates(): Promise<ShiftEntity[]> {
        return this.shiftRepo.find({ order: { startTime: "ASC" } });
    }

    /**
     * Register the doctor for a shift template on a REAL date.
     * The template gives the time-of-day; `dateStr` (YYYY-MM-DD) gives the day.
     */
    async registerShift(doctorId: number, shiftId: number, dateStr: string): Promise<ShiftAssignmentEntity> {
        const template = await this.shiftRepo.findOne({ where: { id: shiftId } });
        if (!template) throw new NotFoundException("Mẫu ca trực không tồn tại");

        const tStart = new Date(template.startTime);
        const tEnd = new Date(template.endTime);
        const [y, m, d] = dateStr.split("-").map(Number);
        const start = new Date(y, m - 1, d, tStart.getHours(), tStart.getMinutes(), 0, 0);
        const end = new Date(y, m - 1, d, tEnd.getHours(), tEnd.getMinutes(), 0, 0);
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

    /** All registered shifts (overview): who works which window. */
    shiftOverview(): Promise<ShiftAssignmentEntity[]> {
        return this.shiftAssignmentRepo.find({
            where: { status: "ACTIVE" },
            relations: ["doctor"],
            order: { startTime: "ASC" },
        });
    }

    /**
     * Free 30-minute slots for a doctor on a date: the doctor's working windows
     * (ACTIVE shift assignments that day) minus slots already booked.
     */
    async availability(doctorId: number, dateStr: string): Promise<string[]> {
        const [y, m, d] = dateStr.split("-").map(Number);
        const dayStart = new Date(y, m - 1, d, 0, 0, 0, 0);
        const dayEnd = new Date(y, m - 1, d, 23, 59, 59, 999);
        const SLOT = 30 * 60 * 1000;

        const windows = await this.shiftAssignmentRepo.find({
            where: { doctor: { id: doctorId }, status: "ACTIVE", startTime: Between(dayStart, dayEnd) },
        });
        const appts = await this.appointmentRepo.find({
            // canceled appointments free up their slot again
            where: { doctor: { id: doctorId }, apTime: Between(dayStart, dayEnd), cancelReason: IsNull() },
        });
        const apptMs = appts.map((a) => new Date(a.apTime).getTime());
        const taken = (slotMs: number) =>
            apptMs.some((am) => am >= slotMs && am < slotMs + SLOT);

        const slots: string[] = [];
        for (const w of windows) {
            let t = new Date(w.startTime).getTime();
            const end = new Date(w.endTime).getTime();
            while (t + SLOT <= end) {
                if (!taken(t)) slots.push(new Date(t).toISOString());
                t += SLOT;
            }
        }
        return [...new Set(slots)].sort();
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

    /**
     * Cancel an assignment. The doctor is still paid for the hours actually worked
     * up to the cancel time (worked = clamp(now, start, end) - start).
     */
    async cancelAssignment(doctorId: number, assignmentId: number): Promise<ShiftAssignmentEntity> {
        const a = await this.assertOwnsAssignment(doctorId, assignmentId);
        const now = Date.now();
        const start = new Date(a.startTime).getTime();
        const end = new Date(a.endTime).getTime();
        const stoppedAt = Math.min(Math.max(now, start), end);
        const worked = Math.max(0, (stoppedAt - start) / 3_600_000);
        await this.shiftAssignmentRepo.update(assignmentId, {
            status: "CANCELED",
            endTime: new Date(stoppedAt),
            duration: Math.round(worked * 100) / 100,
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
            relations: ["patient", "doctor"],
        });
        if (!appt) throw new NotFoundException("Lịch khám không tồn tại");
        if (appt.doctor?.id !== doctorId) throw new ForbiddenException("Không phải lịch của bạn");
        return appt;
    }

    /** Appointment detail (with patient info) for the owning doctor. */
    getAppointmentDetail(doctorId: number, appointmentId: number): Promise<AppointmentEntity> {
        return this.assertOwns(doctorId, appointmentId);
    }

    /** Mark an appointment as examined (confirmCondition 2 = đã khám xong). */
    async completeAppointment(doctorId: number, appointmentId: number): Promise<AppointmentEntity> {
        await this.assertOwns(doctorId, appointmentId);
        await this.appointmentRepo.update({ id: appointmentId }, { confirmCondition: 2 });
        const updated = await this.appointmentRepo.findOne({
            where: { id: appointmentId },
            relations: ["patient"],
        });
        if (!updated) throw new NotFoundException("Lịch khám không tồn tại");
        return updated;
    }

    /** Appointments already examined by this doctor (confirmCondition 2). */
    listCompletedAppointment(doctorId: number): Promise<AppointmentEntity[]> {
        return this.appointmentRepo.find({
            where: { confirmCondition: 2, doctor: { id: doctorId }, cancelReason: IsNull() },
            relations: ["patient"],
            order: { apTime: "DESC" },
        });
    }

    /**
     * Doctor moves a confirmed appointment to a new free slot (its own availability).
     * Allowed once per appointment (shared `rescheduled` flag). Stays confirmed.
     */
    async rescheduleByDoctor(doctorId: number, appointmentId: number, apTime: string): Promise<AppointmentEntity> {
        const appt = await this.assertOwns(doctorId, appointmentId);
        if (appt.cancelReason) throw new BadRequestException("Lịch đã bị hủy");
        if (appt.confirmCondition === 2) throw new BadRequestException("Lịch đã khám xong");
        if (appt.rescheduled) throw new BadRequestException("Lịch chỉ được đổi 1 lần");
        if (!apTime) throw new BadRequestException("Thiếu khung giờ mới");
        await this.appointmentRepo.update(
            { id: appointmentId },
            { apTime: new Date(apTime), rescheduled: true }, // giữ confirmCondition (bác sĩ chọn nên vẫn xác nhận)
        );
        const updated = await this.appointmentRepo.findOne({
            where: { id: appointmentId },
            relations: ["patient"],
        });
        if (!updated) throw new NotFoundException("Lịch khám không tồn tại");
        return updated;
    }

    /** Doctor cancels/rejects an appointment with a reason (sent to the patient). */
    async cancelByDoctor(doctorId: number, appointmentId: number, reason: string): Promise<AppointmentEntity> {
        await this.assertOwns(doctorId, appointmentId);
        await this.appointmentRepo.update(
            { id: appointmentId },
            { cancelReason: reason, canceledBy: "doctor" },
        );
        const updated = await this.appointmentRepo.findOne({
            where: { id: appointmentId },
            relations: ["patient"],
        });
        if (!updated) throw new NotFoundException("Lịch khám không tồn tại");
        return updated;
    }

    /** Follow-up: the doctor creates a NEW (already-confirmed) appointment for a patient. */
    async reExamination(
        doctorId: number,
        patientId: number,
        apTime: string,
        address: string,
        note: string | null,
    ): Promise<AppointmentEntity> {
        const doctor = await this.getDoctor(doctorId);
        const patient = await this.appointmentRepo.manager.findOne(PatientEntity, {
            where: { id: patientId },
        });
        if (!patient) throw new NotFoundException("Bệnh nhân không tồn tại");
        return this.appointmentRepo.save({
            apTime: new Date(apTime),
            confirmDate: new Date(),
            address,
            note: note ?? null,
            confirmCondition: 0, // doctor-created -> already confirmed
            doctorName: doctor.name,
            patient: { id: patientId } as PatientEntity,
            doctor: { id: doctorId } as DoctorEntity,
        });
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
        // confirmCondition 1 = chờ xác nhận (critical-constraints rule 3); bỏ lịch đã hủy
        return this.appointmentRepo.find({
            where: { confirmCondition: 1, doctor: { id: doctorId }, cancelReason: IsNull() },
            relations: ["patient"],
            order: { apTime: "ASC" },
        });
    }

    listAcceptedAppointment(doctorId: number): Promise<AppointmentEntity[]> {
        // confirmCondition 0 = đã xác nhận
        return this.appointmentRepo.find({
            where: { confirmCondition: 0, doctor: { id: doctorId }, cancelReason: IsNull() },
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

    async deleteAppointment(doctorId: number, appointmentId: number): Promise<void> {
        await this.assertOwns(doctorId, appointmentId);
        await this.appointmentRepo.delete(appointmentId);
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
            // doctorNote is the doctor's note (does NOT override the patient's note)
            { doctorNote: note ?? null, confirmCondition: 0, confirmDate: confirmDate } // 0 = đã xác nhận
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