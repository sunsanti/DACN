/** BHYT card: 2 letters + benefit level digit (1-5) + 12 digits, e.g. DN4790123456789. */
export const CARD_REGEX = /^[A-Z]{2}[1-5]\d{12}$/;

export interface InsuranceCard {
    number: string;
    validFrom: string; // yyyy-MM-dd
    validTo: string; // yyyy-MM-dd (inclusive)
}

export type CardStatus = "none" | "valid" | "expired" | "not_yet_valid";

/** Benefit rate from the card's 3rd character (Luật BHYT, đúng tuyến): 1,2,5 → 100%, 3 → 95%, 4 → 80%. */
/** Public-safe card number: first 3 + last 4 characters, the rest masked. */
export function maskCardNumber(number: string): string {
    if (number.length <= 7) return "*".repeat(number.length);
    return number.slice(0, 3) + "*".repeat(number.length - 7) + number.slice(-4);
}

export function rateFromCard(number: string): number {
    const level = number[2];
    if (level === "3") return 0.95;
    if (level === "4") return 0.8;
    return 1;
}

/** Calendar day in the server timezone (Asia/Ho_Chi_Minh), as yyyy-MM-dd. */
const ymd = (d: Date) => d.toLocaleDateString("en-CA", { timeZone: "Asia/Ho_Chi_Minh" });

/** Card validity on the visit day; compared by day, both ends inclusive. */
export function cardStatus(card: InsuranceCard | null, on: Date): CardStatus {
    if (!card) return "none";
    const d = ymd(on);
    if (d < card.validFrom) return "not_yet_valid";
    if (d > card.validTo) return "expired";
    return "valid";
}

export interface BillLine {
    price: number;
    bhytCovered: boolean;
}

/**
 * Only BHYT-covered parts are reimbursed:
 * coveredBase = (exam fee if covered) + Σ covered lines; covered = round(coveredBase × rate) if the card is valid that day.
 */
export function calcBill(
    examFee: number,
    examFeeCovered: boolean,
    lines: BillLine[],
    card: InsuranceCard | null,
    apDate: Date,
) {
    const total = examFee + lines.reduce((a, l) => a + l.price, 0);
    const coveredBase =
        (examFeeCovered ? examFee : 0) + lines.filter((l) => l.bhytCovered).reduce((a, l) => a + l.price, 0);
    const insuranceRate = cardStatus(card, apDate) === "valid" ? rateFromCard(card!.number) : 0;
    const insuranceCovered = Math.round(coveredBase * insuranceRate);
    return { examFee, examFeeCovered, total, coveredBase, insuranceRate, insuranceCovered, payable: total - insuranceCovered };
}
