import { Body, Controller, Post } from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import { RegisterDTO } from "./dto/register.dto";
import { LoginDTO } from "./dto/login.dto";
import { Public } from "../common/decorators/public.decorator";

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
}
