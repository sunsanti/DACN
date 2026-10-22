/**
 * VietQR (NAPAS 247, EMVCo) payload builder — the string a banking app scans to prefill
 * a transfer: receiving bank + account (fixed), amount and transfer note (per appointment).
 */

/** CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF), 4 uppercase hex chars. */
export function crc16(s: string): string {
    let crc = 0xffff;
    for (const byte of Buffer.from(s, "utf8")) {
        crc ^= byte << 8;
        for (let i = 0; i < 8; i++) crc = crc & 0x8000 ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
    }
    return crc.toString(16).toUpperCase().padStart(4, "0");
}

/** EMVCo TLV field: 2-digit id + 2-digit length + value. */
const f = (id: string, value: string) => id + String(value.length).padStart(2, "0") + value;

export interface VietQrInput {
    bin: string; // 6-digit bank BIN, e.g. 970422 (MB)
    accountNo: string;
    amount: number; // VND, positive integer
    content: string; // transfer note, ASCII letters/digits, ≤ 25 chars
}

export function buildVietQr({ bin, accountNo, amount, content }: VietQrInput): string {
    if (!/^\d{6}$/.test(bin)) throw new Error("Invalid bank BIN");
    if (!/^[0-9A-Za-z]{1,19}$/.test(accountNo)) throw new Error("Invalid account number");
    if (!Number.isInteger(amount) || amount <= 0) throw new Error("Amount must be a positive integer");
    if (!/^[0-9A-Za-z ]{1,25}$/.test(content)) throw new Error("Content must be ASCII letters/digits, ≤ 25 chars");

    const payload =
        f("00", "01") +
        f("01", "12") + // dynamic QR (carries an amount)
        f("38", f("00", "A000000727") + f("01", f("00", bin) + f("01", accountNo)) + f("02", "QRIBFTTA")) +
        f("53", "704") +
        f("54", String(amount)) +
        f("58", "VN") +
        f("62", f("08", content)) +
        "6304";
    return payload + crc16(payload);
}
