import { HttpException, Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import PDFDocument from "pdfkit";

export interface DiagnosisItem {
    disease: string;
    confidence?: number;
    reason?: string;
}

/**
 * Orchestrates the AI flow: calls the Python FastAPI service for image diagnosis
 * and Gemini-based symptom analysis, then composes a PDF report for the doctor.
 * The Python service URL comes from AI_SERVICE_URL (default http://localhost:8000).
 */
@Injectable()
export class AiService {
    private readonly baseUrl: string;

    constructor(private readonly config: ConfigService) {
        this.baseUrl =
            this.config.get<string>("AI_SERVICE_URL") ?? "http://localhost:8000";
    }

    /** Forward an uploaded image to the Python /predict endpoint. */
    async diagnoseImage(file: Express.Multer.File): Promise<any> {
        if (!file) {
            throw new HttpException("Thiếu file ảnh (field 'image').", 400);
        }
        const form = new FormData();
        form.append(
            "file",
            new Blob([new Uint8Array(file.buffer)], { type: file.mimetype }),
            file.originalname || "upload.jpg",
        );
        return this.postForm(`${this.baseUrl}/predict`, form);
    }

    /** Forward a symptom description to the Python /chat (Gemini) endpoint. */
    async chat(symptoms: string): Promise<any> {
        return this.postJson(`${this.baseUrl}/chat`, { symptoms });
    }

    /**
     * Build the combined preliminary-diagnosis PDF the doctor receives:
     * image-model top-3 + Gemini symptom top-3.
     */
    async buildReport(
        file: Express.Multer.File | undefined,
        symptoms?: string,
    ): Promise<Buffer> {
        const image = file ? await this.diagnoseImage(file) : null;
        const chat = symptoms?.trim() ? await this.chat(symptoms.trim()) : null;
        return this.renderPdf({
            symptoms,
            imageResults: image?.results ?? [],
            chatResults: Array.isArray(chat?.results) ? chat.results : [],
        });
    }

    // ---- helpers -------------------------------------------------------------

    private async postForm(url: string, form: FormData): Promise<any> {
        let res: Response;
        try {
            res = await fetch(url, { method: "POST", body: form });
        } catch (e) {
            throw new HttpException(
                `Không kết nối được AI service (${this.baseUrl}). Đã chạy uvicorn chưa?`,
                503,
            );
        }
        return this.parse(res);
    }

    private async postJson(url: string, body: unknown): Promise<any> {
        let res: Response;
        try {
            res = await fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(body),
            });
        } catch (e) {
            throw new HttpException(
                `Không kết nối được AI service (${this.baseUrl}). Đã chạy uvicorn chưa?`,
                503,
            );
        }
        return this.parse(res);
    }

    private async parse(res: Response): Promise<any> {
        const text = await res.text();
        if (!res.ok) {
            throw new HttpException(text || "AI service error", res.status);
        }
        try {
            return JSON.parse(text);
        } catch {
            return { raw: text };
        }
    }

    private renderPdf(data: {
        symptoms?: string;
        imageResults: DiagnosisItem[];
        chatResults: DiagnosisItem[];
    }): Promise<Buffer> {
        return new Promise((resolve, reject) => {
            const doc = new PDFDocument({ margin: 50 });
            const chunks: Buffer[] = [];
            doc.on("data", (c: Buffer) => chunks.push(c));
            doc.on("end", () => resolve(Buffer.concat(chunks)));
            doc.on("error", reject);

            // NOTE: pdfkit's built-in fonts do not cover Vietnamese diacritics.
            // To render Vietnamese reasons correctly, drop a Unicode TTF into
            // backend/src/ai/assets/ and call doc.font(<path>) here.
            doc.fontSize(18).text("PRELIMINARY AI DIAGNOSIS REPORT", { align: "center" });
            doc.moveDown(0.5);
            doc.fontSize(10).fillColor("gray")
                .text(`Generated: ${new Date().toISOString()}`, { align: "center" });
            doc.fillColor("black").moveDown(1);

            if (data.symptoms) {
                doc.fontSize(12).text("Symptoms (patient):", { underline: true });
                doc.fontSize(11).text(data.symptoms);
                doc.moveDown(1);
            }

            doc.fontSize(12).text("1) Image model (Swin V2) - Top 3:", { underline: true });
            this.writeItems(doc, data.imageResults);
            doc.moveDown(1);

            doc.fontSize(12).text("2) Symptom analysis (Gemini) - Top 3:", { underline: true });
            this.writeItems(doc, data.chatResults);
            doc.moveDown(1.5);

            doc.fontSize(9).fillColor("gray").text(
                "Luu y: ket qua AI chi mang tinh tham khao, khong thay the chan doan cua bac si.",
            );
            doc.end();
        });
    }

    private writeItems(doc: PDFKit.PDFDocument, items: DiagnosisItem[]) {
        if (!items || items.length === 0) {
            doc.fontSize(11).fillColor("gray").text("  (no data)").fillColor("black");
            return;
        }
        items.forEach((it, i) => {
            const pct =
                typeof it.confidence === "number"
                    ? ` - ${(it.confidence * 100).toFixed(1)}%`
                    : "";
            doc.fontSize(11).fillColor("black").text(`  Top ${i + 1}: ${it.disease}${pct}`);
            if (it.reason) {
                doc.fontSize(9).fillColor("gray").text(`        ${it.reason}`).fillColor("black");
            }
        });
    }
}
