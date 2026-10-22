import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { BhytRegistryEntity } from "./bhyt-registry.entity";
import { InsuranceCard, cardStatus, rateFromCard } from "./billing.util";

/** Calendar day in the server timezone (Asia/Ho_Chi_Minh), as yyyy-MM-dd. */
const ymd = (d: Date | string) =>
    typeof d === "string" ? d.slice(0, 10) : d.toLocaleDateString("en-CA", { timeZone: "Asia/Ho_Chi_Minh" });

/** BHYT lookup by CCCD in the read-only registry. */
@Injectable()
export class BhytService {
    constructor(@InjectRepository(BhytRegistryEntity) private readonly repo: Repository<BhytRegistryEntity>) {}

    /** The card for this CCCD, only if the registry's birth date matches the patient's (spec 04, Q2). */
    async findCard(cccd: string | null | undefined, birthDate: Date | string): Promise<InsuranceCard | null> {
        if (!cccd) return null;
        const r = await this.repo.findOne({ where: { cccd } });
        if (!r || ymd(r.birthDate) !== ymd(birthDate)) return null;
        return { number: r.cardNumber, validFrom: ymd(r.validFrom), validTo: ymd(r.validTo) };
    }

    /** Shape shown on the patient profile; null = no BHYT (the app hides the field). */
    static describe(card: InsuranceCard | null, on = new Date()) {
        if (!card) return null;
        return {
            cardNumber: card.number,
            validFrom: card.validFrom,
            validTo: card.validTo,
            rate: rateFromCard(card.number),
            status: cardStatus(card, on),
        };
    }
}
