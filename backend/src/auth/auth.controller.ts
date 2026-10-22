import {
    BadRequestException,
    Body,
    Controller,
    HttpCode,
    Post,
    UploadedFile,
    UseGuards,
    UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ThrottlerGuard } from "@nestjs/throttler";
import { ApiBearerAuth, ApiConsumes, ApiTags } from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import { RegisterDTO } from "./dto/register.dto";
import { RegisterDoctorDTO } from "./dto/register-doctor.dto";
import { LoginDTO } from "./dto/login.dto";
import { BhytLookupDto } from "./dto/bhyt-lookup.dto";
import { Public } from "../common/decorators/public.decorator";
import { Roles } from "../common/decorators/roles.decorator";
import { CleanupUploadOnError, imageUpload, toPublicPath } from "../common/upload";
import { BhytService } from "../billing/bhyt.service";
import { maskCardNumber } from "../billing/billing.util";

@ApiTags("auth")
@Controller("auth")
export class AuthController {
    constructor(
        private readonly authService: AuthService,
        private readonly bhytService: BhytService,
    ) {}

    /** multipart/form-data; `avatar` (ảnh) tuỳ chọn. */
    @Public()
    @Post("register")
    @ApiConsumes("multipart/form-data", "application/json")
    @UseInterceptors(FileInterceptor("avatar", imageUpload("avatars")), CleanupUploadOnError)
    register(@Body() dto: RegisterDTO, @UploadedFile() avatar?: Express.Multer.File) {
        return this.authService.register(dto, toPublicPath(avatar));
    }

    /**
     * Pre-registration BHYT preview. Needs CCCD + birth date (findCard checks both),
     * returns only a masked card number, and is rate-limited per IP against CCCD probing.
     */
    @Public()
    @UseGuards(ThrottlerGuard)
    @Post("bhyt-lookup")
    @HttpCode(200)
    async bhytLookup(@Body() dto: BhytLookupDto) {
        const card = BhytService.describe(await this.bhytService.findCard(dto.cccd, dto.birthDate));
        if (!card) return { found: false };
        return {
            found: true,
            cardNumber: maskCardNumber(card.cardNumber),
            rate: card.rate,
            validTo: card.validTo,
            status: card.status,
        };
    }

    @Public()
    @Post("login")
    login(@Body() dto: LoginDTO) {
        return this.authService.login(dto);
    }

    /** Admin creates a doctor account (multipart; `avatar` bắt buộc để nhận diện bác sĩ). */
    @ApiBearerAuth()
    @Roles("admin")
    @Post("register-doctor")
    @ApiConsumes("multipart/form-data")
    @UseInterceptors(FileInterceptor("avatar", imageUpload("avatars")), CleanupUploadOnError)
    registerDoctor(@Body() dto: RegisterDoctorDTO, @UploadedFile() avatar?: Express.Multer.File) {
        if (!avatar) throw new BadRequestException("Bác sĩ phải có ảnh đại diện");
        return this.authService.registerDoctor(dto, toPublicPath(avatar));
    }
}
