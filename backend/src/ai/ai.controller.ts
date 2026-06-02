import {
    Body,
    Controller,
    Post,
    Res,
    UploadedFile,
    UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ApiBody, ApiConsumes, ApiTags } from "@nestjs/swagger";
import type { Response } from "express";
import { AiService } from "./ai.service";
import { ChatDTO } from "./dto/chat.dto";

@ApiTags("ai")
@Controller("ai")
export class AiController {
    constructor(private readonly aiService: AiService) {}

    /** Chẩn đoán ảnh: gửi 1 ảnh -> top-3 bệnh từ model Swin V2. */
    @Post("diagnose-image")
    @ApiConsumes("multipart/form-data")
    @ApiBody({
        schema: {
            type: "object",
            required: ["image"],
            properties: { image: { type: "string", format: "binary" } },
        },
    })
    @UseInterceptors(FileInterceptor("image"))
    diagnoseImage(@UploadedFile() image: Express.Multer.File) {
        return this.aiService.diagnoseImage(image);
    }

    /** Chatbox: gửi mô tả triệu chứng -> top-3 bệnh từ Gemini. */
    @Post("chat")
    chat(@Body() dto: ChatDTO) {
        return this.aiService.chat(dto.symptoms);
    }

    /** Tổng hợp ảnh + triệu chứng -> file PDF chẩn đoán sơ bộ gửi bác sĩ. */
    @Post("report")
    @ApiConsumes("multipart/form-data")
    @ApiBody({
        schema: {
            type: "object",
            properties: {
                image: { type: "string", format: "binary" },
                symptoms: { type: "string" },
            },
        },
    })
    @UseInterceptors(FileInterceptor("image"))
    async report(
        @UploadedFile() image: Express.Multer.File,
        @Body("symptoms") symptoms: string,
        @Res() res: Response,
    ) {
        const pdf = await this.aiService.buildReport(image, symptoms);
        res.set({
            "Content-Type": "application/pdf",
            "Content-Disposition": 'attachment; filename="ai-report.pdf"',
            "Content-Length": pdf.length.toString(),
        });
        res.end(pdf);
    }
}
