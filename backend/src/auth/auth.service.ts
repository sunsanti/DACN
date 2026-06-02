import {
    ConflictException,
    Injectable,
    UnauthorizedException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { JwtService } from "@nestjs/jwt";
import { Repository } from "typeorm";
import * as bcrypt from "bcrypt";
import { AccountEntity } from "./entities/account.entity";
import { PatientEntity } from "../patient/entities/patient.entity";
import { RegisterDTO } from "./dto/register.dto";
import { LoginDTO } from "./dto/login.dto";
import { JwtPayload } from "./jwt-payload.interface";

@Injectable()
export class AuthService {
    constructor(
        @InjectRepository(AccountEntity)
        private readonly accountRepo: Repository<AccountEntity>,
        @InjectRepository(PatientEntity)
        private readonly patientRepo: Repository<PatientEntity>,
        private readonly jwt: JwtService,
    ) {}

    /** Self-service patient registration: creates a patient record + linked account. */
    async register(dto: RegisterDTO) {
        const exists = await this.accountRepo.findOne({ where: { email: dto.email } });
        if (exists) throw new ConflictException("Email đã tồn tại");

        const patient = await this.patientRepo.save({
            name: dto.name,
            gender: dto.gender,
            age: dto.age,
            birthDate: new Date(dto.birthDate),
            email: dto.email,
            phone: dto.phone,
            address: dto.address,
            createAt: new Date(),
            avatar: "",
        });

        const passwordHash = await bcrypt.hash(dto.password, 10);
        const account = await this.accountRepo.save({
            email: dto.email,
            passwordHash,
            role: "patient",
            patient,
            doctor: null,
        });

        return this.sign(account);
    }

    async login(dto: LoginDTO) {
        const account = await this.accountRepo.findOne({
            where: { email: dto.email },
            relations: ["patient", "doctor"],
        });
        if (!account || !(await bcrypt.compare(dto.password, account.passwordHash))) {
            throw new UnauthorizedException("Email hoặc mật khẩu không đúng");
        }
        return this.sign(account);
    }

    private sign(account: AccountEntity) {
        const payload: JwtPayload = {
            sub: account.id,
            role: account.role,
            patientId: account.patient?.id,
            doctorId: account.doctor?.id,
        };
        return {
            accessToken: this.jwt.sign(payload),
            role: payload.role,
            patientId: payload.patientId,
            doctorId: payload.doctorId,
        };
    }
}
