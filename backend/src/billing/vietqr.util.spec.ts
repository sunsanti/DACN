import { buildVietQr, crc16 } from "./vietqr.util";

/** Split an EMVCo string into [id, value] pairs (top level). */
const fields = (s: string) => {
    const out: [string, string][] = [];
    for (let i = 0; i < s.length; ) {
        const id = s.slice(i, i + 2);
        const len = Number(s.slice(i + 2, i + 4));
        out.push([id, s.slice(i + 4, i + 4 + len)]);
        i += 4 + len;
    }
    return out;
};

const qr = () => buildVietQr({ bin: "970422", accountNo: "0123456789", amount: 120000, content: "DACN17" });

describe("vietqr.util", () => {
    it("crc16: CRC-16/CCITT-FALSE check value", () => {
        expect(crc16("123456789")).toBe("29B1");
    });

    it("fields in order with correct lengths and values", () => {
        const f = fields(qr());
        expect(f.map(([id]) => id)).toEqual(["00", "01", "38", "53", "54", "58", "62", "63"]);
        const m = Object.fromEntries(f);
        expect(m["00"]).toBe("01");
        expect(m["01"]).toBe("12"); // dynamic QR
        expect(m["53"]).toBe("704");
        expect(m["54"]).toBe("120000");
        expect(m["58"]).toBe("VN");
        expect(Object.fromEntries(fields(m["62"]))["08"]).toBe("DACN17");
        const acc = Object.fromEntries(fields(m["38"]));
        expect(acc["00"]).toBe("A000000727");
        expect(acc["02"]).toBe("QRIBFTTA");
        expect(Object.fromEntries(fields(acc["01"]))).toEqual({ "00": "970422", "01": "0123456789" });
    });

    it("CRC covers everything up to and including '6304'", () => {
        const s = qr();
        expect(s.slice(-8, -4)).toBe("6304");
        expect(s.slice(-4)).toBe(crc16(s.slice(0, -4)));
        const tampered = s.replace("120000", "120001");
        expect(tampered.slice(-4)).not.toBe(crc16(tampered.slice(0, -4)));
    });

    it("rejects bad input", () => {
        const base = { bin: "970422", accountNo: "0123456789", amount: 1000, content: "DACN1" };
        expect(() => buildVietQr({ ...base, amount: 0 })).toThrow();
        expect(() => buildVietQr({ ...base, amount: 10.5 })).toThrow();
        expect(() => buildVietQr({ ...base, content: "Thanh toán" })).toThrow(); // non-ASCII
        expect(() => buildVietQr({ ...base, bin: "97042" })).toThrow();
    });
});
