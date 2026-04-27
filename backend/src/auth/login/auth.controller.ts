import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) { }

  @Post('register')
  async register(@Body() body: any) {
    // Truyền thẳng toàn bộ body (email, password, name, age...) vào Service
    return await this.authService.register(body);
  }

  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() body: any) {
    // Chỉ cần truyền email và password để quét ở cả 2 bảng
    return await this.authService.login(body.email, body.password);
  }
}