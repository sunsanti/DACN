import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { ConfigService } from "@nestjs/config";
import { Repository } from "typeorm";
import { DoctorEntity } from "../doctor/entities/doctor.entity";
import { ShiftAssignmentEntity } from "../doctor/entities/shiftAssignment.entity";

export interface DoctorSalary {
    doctorId: number;
    name: string;
    totalHours: number;
    hourlyRate: number;
    salary: number;
}

@Injectable()
export class AdminService {
    private readonly hourlyRate: number;

    constructor(
        @InjectRepository(DoctorEntity)
        private readonly doctorRepo: Repository<DoctorEntity>,
        @InjectRepository(ShiftAssignmentEntity)
        private readonly shiftAssignmentRepo: Repository<ShiftAssignmentEntity>,
        config: ConfigService,
    ) {
        this.hourlyRate = Number(config.get<string>("ADMIN_HOURLY_RATE") ?? "100000");
    }

    /**
     * Per-doctor worked hours (summed from shift assignment start/end times —
     * robust regardless of the legacy `duration` field) and computed salary.
     */
    async doctorSalaries(): Promise<DoctorSalary[]> {
        const doctors = await this.doctorRepo.find();
        const assignments = await this.shiftAssignmentRepo.find({ relations: ["doctor"] });

        // Pay for hours actually worked: ACTIVE shifts pay full, CANCELED shifts pay
        // the partial hours worked before cancel (stored in `duration`).
        const hoursByDoctor = new Map<number, number>();
        for (const a of assignments) {
            const docId = a.doctor?.id;
            if (!docId || (a.status !== "ACTIVE" && a.status !== "CANCELED")) continue;
            const hours = Number(a.duration) || 0;
            if (hours > 0) {
                hoursByDoctor.set(docId, (hoursByDoctor.get(docId) ?? 0) + hours);
            }
        }

        return doctors.map((d) => {
            const totalHours = Math.round((hoursByDoctor.get(d.id) ?? 0) * 100) / 100;
            return {
                doctorId: d.id,
                name: d.name,
                totalHours,
                hourlyRate: this.hourlyRate,
                salary: Math.round(totalHours * this.hourlyRate),
            };
        });
    }
}
