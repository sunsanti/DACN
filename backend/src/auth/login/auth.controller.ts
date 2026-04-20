import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UserRole } from '../../users/entities/user.entity';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }

  @Post('register')
  async register(@Body() body: any) {
    console.log("=== DỮ LIỆU FLUTTER GỬI LÊN LÚC REGISTER ===")
    const { email, password, role } = body;
    const userRole = role ? (role as UserRole) : UserRole.PATIENT;

    const user = await this.authService.register(email, password, userRole);
    // Xóa password trước khi trả về client
    const { password: _, ...result } = user;
    return result;
  }

  @Post('login')
  async login(@Body() body: any) {
    console.log("=== DỮ LIỆU FLUTTER GỬI LÊN LÚC LOGIN ===");
    const { email, password } = body;
    return this.authService.login(email, password);
  }
}
