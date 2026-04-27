import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { Patient } from '../../patient/entities/patient.entity';
import { Doctor } from '../../doctor/entities/doctor.entity';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Patient) private patientRepo: Repository<Patient>,
    @InjectRepository(Doctor) private doctorRepo: Repository<Doctor>,
    private jwtService: JwtService,
  ) { }

  // 1. ĐĂNG KÝ (Chỉ dành cho Bệnh nhân)
  async register(data: any) {
    const { email, password, name, age } = data;

    const exist = await this.patientRepo.findOne({ where: { email } });
    if (exist) throw new ConflictException('Email này đã được sử dụng!');

    const hashedPassword = await bcrypt.hash(password, 10);
    const newPatient = this.patientRepo.create({
      email,
      password: hashedPassword,
      name,
      age
    });

    return await this.patientRepo.save(newPatient);
  }

  // 2. ĐĂNG NHẬP (Tự động nhận diện Role)
  async login(email: string, pass: string) {
    let user: any = null;
    let role: 'PATIENT' | 'DOCTOR' = 'PATIENT';

    // Quét bảng Patient trước
    user = await this.patientRepo.findOne({ where: { email } });

    // Nếu không có, quét tiếp bảng Doctor
    if (!user) {
      user = await this.doctorRepo.findOne({ where: { email } });
      role = 'DOCTOR';
    }

    if (!user) throw new UnauthorizedException('Sai email hoặc tài khoản không tồn tại!');

    const isMatch = await bcrypt.compare(pass, user.password);
    if (!isMatch) throw new UnauthorizedException('Sai mật khẩu rồi Quý ơi!');

    const payload = { sub: user.id, email: user.email, role: role };
    return {
      access_token: await this.jwtService.signAsync(payload),
      role: role // Cực kỳ hữu ích để Flutter biết chuyển hướng sang màn hình nào
    };
  }
}