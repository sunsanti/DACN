import { ValidationPipe } from "@nestjs/common";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";
import { BhytLookupDto } from "./dto/bhyt-lookup.dto";
import { BhytService } from "../billing/bhyt.service";

describe("AuthController.bhytLookup", () => {
    const card = { number: "DN4790123451234", validFrom: "2026-01-01", validTo: "2099-12-31" };
    const findCard = jest.fn();
    const controller = new AuthController({} as unknown as AuthService, { findCard } as unknown as BhytService);

    it("returns a masked card when CCCD + birth date match", async () => {
        findCard.mockResolvedValue(card);
        const r = await controller.bhytLookup({ cccd: "079012345689", birthDate: "2000-01-01" });
        expect(r).toEqual({ found: true, cardNumber: "DN4********1234", rate: 0.8, validTo: "2099-12-31", status: "valid" });
        expect(JSON.stringify(r)).not.toContain(card.number);
    });

    it("returns found:false when no card (e.g. birth date mismatch)", async () => {
        findCard.mockResolvedValue(null);
        expect(await controller.bhytLookup({ cccd: "079012345689", birthDate: "1999-01-01" })).toEqual({ found: false });
    });

    it("rejects a CCCD that is not 12 digits", async () => {
        const pipe = new ValidationPipe();
        await expect(
            pipe.transform({ cccd: "07901234568", birthDate: "2000-01-01" }, { type: "body", metatype: BhytLookupDto }),
        ).rejects.toThrow();
    });
});
