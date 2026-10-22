import { ConflictException, Injectable, NotFoundException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { InjectRepository } from "@nestjs/typeorm";
import { QueryFailedError, Repository } from "typeorm";
import { DiseaseEntity } from "./disease.entity";
import { CreateDiseaseDTO, UpdateDiseaseDTO } from "./disease.dto";

@Injectable()
export class DiseaseService {
    /** Phí khám cố định cho mọi lượt khám (env EXAM_FEE, VND). */
    readonly examFee: number;
    /** Phí khám có được BHYT chi trả (env EXAM_FEE_BHYT_COVERED, mặc định true). */
    readonly examFeeBhytCovered: boolean;

    constructor(
        @InjectRepository(DiseaseEntity) private readonly repo: Repository<DiseaseEntity>,
        config: ConfigService,
    ) {
        this.examFee = Number(config.get<string>("EXAM_FEE") ?? "150000");
        this.examFeeBhytCovered = (config.get<string>("EXAM_FEE_BHYT_COVERED") ?? "true") !== "false";
    }

    /** Admin thấy tất cả; bác sĩ chỉ thấy bệnh đang bật. */
    async list(onlyActive: boolean) {
        const items = await this.repo.find({
            where: onlyActive ? { active: true } : {},
            order: { name: "ASC" },
        });
        return { examFee: this.examFee, examFeeBhytCovered: this.examFeeBhytCovered, items };
    }

    create(dto: CreateDiseaseDTO) {
        return this.save(this.repo.create({ name: dto.name.trim(), price: dto.price, bhytCovered: dto.bhytCovered ?? true }));
    }

    async update(id: number, dto: UpdateDiseaseDTO) {
        const d = await this.repo.findOne({ where: { id } });
        if (!d) throw new NotFoundException("Bệnh không tồn tại");
        Object.assign(d, { ...dto, name: dto.name?.trim() ?? d.name });
        return this.save(d);
    }

    private async save(d: DiseaseEntity) {
        try {
            return await this.repo.save(d);
        } catch (e) {
            // 23505 = unique_violation (tên bệnh trùng)
            const code = (e as QueryFailedError<Error & { code?: string }>).driverError?.code;
            if (e instanceof QueryFailedError && code === "23505") {
                throw new ConflictException("Tên bệnh đã tồn tại");
            }
            throw e;
        }
    }
}
