import { Body, Controller, Post } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import { RegisterDTO } from "./dto/register.dto";
import { RegisterDoctorDTO } from "./dto/register-doctor.dto";
import { LoginDTO } from "./dto/login.dto";
import { Public } from "../common/decorators/public.decorator";
import { Roles } from "../common/decorators/roles.decorator";

@ApiTags("auth")
@Controller("auth")
export class AuthController {
    constructor(private readonly authService: AuthService) {}

    @Public()
    @Post("register")
    register(@Body() dto: RegisterDTO) {
        return this.authService.register(dto);
    }

    @Public()
    @Post("login")
    login(@Body() dto: LoginDTO) {
        return this.authService.login(dto);
    }

    /** Admin creates a doctor account (the patient self-registers, doctors do not). */
    @ApiBearerAuth()
    @Roles("admin")
    @Post("register-doctor")
    registerDoctor(@Body() dto: RegisterDoctorDTO) {
        return this.authService.registerDoctor(dto);
    }
}
