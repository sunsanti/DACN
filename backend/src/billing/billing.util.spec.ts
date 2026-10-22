import { calcBill, cardStatus, maskCardNumber, rateFromCard } from "./billing.util";

const card = (number: string, validFrom: string, validTo: string) => ({ number, validFrom, validTo });
const day = (s: string) => new Date(`${s}T09:00:00+07:00`);
const yes = (price: number) => ({ price, bhytCovered: true });
const no = (price: number) => ({ price, bhytCovered: false });
const c80 = card("DN4790123456789", "2026-01-01", "2026-12-31");

describe("billing.util", () => {
    it("rateFromCard: level digit 1,2,5 → 100%, 3 → 95%, 4 → 80%", () => {
        expect(rateFromCard("DN1790123456789")).toBe(1);
        expect(rateFromCard("DN2790123456789")).toBe(1);
        expect(rateFromCard("DN5790123456789")).toBe(1);
        expect(rateFromCard("DN3790123456789")).toBe(0.95);
        expect(rateFromCard("DN4790123456789")).toBe(0.8);
    });

    it("cardStatus: none / valid / expired / not_yet_valid, inclusive by day", () => {
        expect(cardStatus(null, day("2026-06-01"))).toBe("none");
        expect(cardStatus(c80, day("2026-06-01"))).toBe("valid");
        expect(cardStatus(c80, day("2026-01-01"))).toBe("valid");
        expect(cardStatus(c80, new Date("2026-12-31T23:30:00+07:00"))).toBe("valid"); // last day, late evening
        expect(cardStatus(c80, day("2027-01-01"))).toBe("expired");
        expect(cardStatus(c80, day("2025-12-31"))).toBe("not_yet_valid");
    });

    it("spec example: covered exam fee + covered line + uncovered line, 80% card", () => {
        expect(calcBill(150000, true, [yes(50000), no(80000)], c80, day("2026-06-01"))).toEqual({
            examFee: 150000, examFeeCovered: true, total: 280000, coveredBase: 200000,
            insuranceRate: 0.8, insuranceCovered: 160000, payable: 120000,
        });
    });

    it("no card → patient pays everything", () => {
        const b = calcBill(150000, true, [yes(50000)], null, day("2026-06-01"));
        expect(b).toMatchObject({ total: 200000, insuranceRate: 0, insuranceCovered: 0, payable: 200000 });
    });

    it("expired / not yet valid card → no coverage", () => {
        const expired = card("DN4790123456789", "2025-01-01", "2025-12-31");
        const future = card("DN4790123456789", "2027-01-01", "2027-12-31");
        expect(calcBill(150000, true, [yes(50000)], expired, day("2026-06-01")).insuranceCovered).toBe(0);
        expect(calcBill(150000, true, [yes(50000)], future, day("2026-06-01")).payable).toBe(200000);
    });

    it("exam fee not covered → only covered lines count", () => {
        const b = calcBill(150000, false, [yes(100000), no(30000)], c80, day("2026-06-01"));
        expect(b).toMatchObject({ total: 280000, coveredBase: 100000, insuranceCovered: 80000, payable: 200000 });
    });

    it("nothing covered (coveredBase 0) → BHYT pays 0 even with a valid card", () => {
        const b = calcBill(150000, false, [no(50000)], c80, day("2026-06-01"));
        expect(b).toMatchObject({ coveredBase: 0, insuranceCovered: 0, payable: 200000 });
    });

    it("100% card and every line covered → payable 0", () => {
        const full = card("TE1480000000003", "2026-01-01", "2026-12-31");
        expect(calcBill(150000, true, [yes(50000), yes(100000)], full, day("2026-06-01")).payable).toBe(0);
    });

    it("95% rounding to whole đồng; covered + payable = total", () => {
        const l3 = card("HC3790123456789", "2026-01-01", "2026-12-31");
        const b = calcBill(150000, true, [yes(5555)], l3, day("2026-06-01")); // 155555 × 0.95 = 147777.25
        expect(b.insuranceCovered).toBe(147777);
        expect(b.payable).toBe(7778);
        expect(b.insuranceCovered + b.payable).toBe(b.total);
    });
});

describe("maskCardNumber", () => {
    it("keeps first 3 + last 4 of a 15-char card", () => {
        expect(maskCardNumber("DN4790123451234")).toBe("DN4********1234");
    });
    it("masks everything when too short to keep both ends", () => {
        expect(maskCardNumber("ABC1234")).toBe("*******");
    });
});
