import { ForbiddenException, HttpException, Injectable, NotFoundException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import PDFDocument from "pdfkit";
import * as fs from "fs";
import { MedicalReportEntity } from "../patient/entities/medical_report.entity";
import { AppointmentEntity } from "../patient/entities/appointment.entity";

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

    constructor(
        private readonly config: ConfigService,
        @InjectRepository(MedicalReportEntity)
        private readonly reportRepo: Repository<MedicalReportEntity>,
        @InjectRepository(AppointmentEntity)
        private readonly appointmentRepo: Repository<AppointmentEntity>,
    ) {
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
        appointmentId?: number,
        patientId?: number,
    ): Promise<Buffer> {
        // Verify the appointment belongs to the requesting patient BEFORE doing any
        // work, so a patient cannot attach a report to someone else's appointment.
        if (appointmentId) {
            const appt = await this.appointmentRepo.findOne({
                where: { id: appointmentId },
                relations: ["patient"],
            });
            if (!appt) throw new NotFoundException("Lịch khám không tồn tại");
            if (patientId && appt.patient?.id !== patientId) {
                throw new ForbiddenException("Lịch khám không thuộc về bạn");
            }
        }

        const image = file ? await this.diagnoseImage(file) : null;
        const chat = symptoms?.trim() ? await this.chat(symptoms.trim()) : null;
        const pdf = await this.renderPdf({
            symptoms,
            imageBuffer: file?.buffer,
            imageResults: image?.results ?? [],
            chatResults: Array.isArray(chat?.results) ? chat.results : [],
        });
        // Persist the report linked to the appointment so the doctor can fetch it later.
        if (appointmentId) {
            await this.reportRepo.save({
                appointment: { id: appointmentId } as AppointmentEntity,
                pdf,
            });
        }
        return pdf;
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

    /**
     * Resolve a Unicode TTF that supports Vietnamese diacritics.
     * Order: AI_PDF_FONT env override -> common Windows/macOS/Linux system fonts.
     * pdfkit's built-in Helvetica does NOT render Vietnamese, hence this.
     */
    private resolveFonts(): { regular: string | null; bold: string | null } {
        const exists = (p?: string | null) => {
            try {
                return !!p && fs.existsSync(p);
            } catch {
                return false;
            }
        };
        const pick = (arr: (string | undefined)[]) =>
            arr.find((p) => exists(p)) ?? null;

        return {
            regular: pick([
                this.config.get<string>("AI_PDF_FONT"),
                "C:/Windows/Fonts/arial.ttf",
                "C:/Windows/Fonts/segoeui.ttf",
                "/Library/Fonts/Arial.ttf",
                "/System/Library/Fonts/Supplemental/Arial.ttf",
                "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            ]),
            bold: pick([
                this.config.get<string>("AI_PDF_FONT_BOLD"),
                "C:/Windows/Fonts/arialbd.ttf",
                "C:/Windows/Fonts/segoeuib.ttf",
                "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            ]),
        };
    }

    private renderPdf(data: {
        symptoms?: string;
        imageBuffer?: Buffer;
        imageResults: DiagnosisItem[];
        chatResults: DiagnosisItem[];
    }): Promise<Buffer> {
        return new Promise((resolve, reject) => {
            const doc = new PDFDocument({ margin: 50 });
            const chunks: Buffer[] = [];
            doc.on("data", (c: Buffer) => chunks.push(c));
            doc.on("end", () => resolve(Buffer.concat(chunks)));
            doc.on("error", reject);

            // Register a Vietnamese-capable font (falls back to Helvetica if none found).
            const fonts = this.resolveFonts();
            if (fonts.regular) doc.registerFont("body", fonts.regular);
            if (fonts.bold) doc.registerFont("bold", fonts.bold);
            const FONT = fonts.regular ? "body" : "Helvetica";
            const BOLD = fonts.bold ? "bold" : FONT;

            doc.font(BOLD).fontSize(18).text("BÁO CÁO CHẨN ĐOÁN SƠ BỘ (AI)", {
                align: "center",
            });
            doc.moveDown(0.5);
            doc.font(FONT).fontSize(10).fillColor("gray")
                .text(`Tạo lúc: ${new Date().toLocaleString("vi-VN")}`, { align: "center" });
            doc.fillColor("black").moveDown(1);

            // Patient image (embedded). pdfkit's doc.image() does NOT advance the
            // text cursor, so we draw at a fixed box then move doc.y below it to
            // avoid the following text overlapping the picture.
            if (data.imageBuffer && data.imageBuffer.length) {
                doc.font(BOLD).fontSize(12).text("Ảnh bệnh nhân cung cấp:");
                doc.moveDown(0.3);
                const boxH = 240;
                const top = doc.y;
                const left = doc.page.margins.left;
                try {
                    doc.image(data.imageBuffer, left, top, { fit: [240, boxH] });
                    doc.y = top + boxH + 12; // reserve the full image box height
                    doc.x = left;
                } catch {
                    doc.font(FONT).fontSize(10).fillColor("gray")
                        .text("(Không hiển thị được ảnh — định dạng không hỗ trợ)")
                        .fillColor("black");
                }
                doc.moveDown(0.5);
            }

            if (data.symptoms) {
                doc.font(BOLD).fontSize(12).text("Triệu chứng (bệnh nhân mô tả):");
                doc.font(FONT).fontSize(11).text(data.symptoms);
                doc.moveDown(1);
            }

            doc.font(BOLD).fontSize(12).text("1) Mô hình ảnh (Swin V2) — Top 3:");
            this.writeItems(doc, data.imageResults, FONT, BOLD);
            doc.moveDown(1);

            doc.font(BOLD).fontSize(12).text("2) Phân tích triệu chứng (Gemini) — Top 3:");
            this.writeItems(doc, data.chatResults, FONT, BOLD);
            doc.moveDown(1.5);

            doc.font(FONT).fontSize(9).fillColor("gray").text(
                "Lưu ý: kết quả AI chỉ mang tính tham khảo, không thay thế chẩn đoán của bác sĩ.",
            );
            doc.end();
        });
    }

    private writeItems(
        doc: PDFKit.PDFDocument,
        items: DiagnosisItem[],
        FONT: string,
        BOLD: string,
    ) {
        if (!items || items.length === 0) {
            doc.font(FONT).fontSize(11).fillColor("gray").text("   (không có dữ liệu)")
                .fillColor("black");
            return;
        }
        items.forEach((it, i) => {
            const pct =
                typeof it.confidence === "number"
                    ? ` — ${(it.confidence * 100).toFixed(1)}%`
                    : "";
            doc.font(BOLD).fontSize(11).fillColor("black")
                .text(`   Top ${i + 1}: ${it.disease}${pct}`);
            if (it.reason) {
                doc.font(FONT).fontSize(9).fillColor("gray")
                    .text(`        ${it.reason}`).fillColor("black");
            }
        });
    }
}
