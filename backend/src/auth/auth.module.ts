import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { JwtModule } from "@nestjs/jwt";
import { TypeOrmModule } from "@nestjs/typeorm";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";
import { AccountEntity } from "./entities/account.entity";
import { PatientEntity } from "../patient/entities/patient.entity";
import { DoctorEntity } from "../doctor/entities/doctor.entity";

@Module({
    imports: [
        TypeOrmModule.forFeature([AccountEntity, PatientEntity, DoctorEntity]),
        JwtModule.registerAsync({
            global: true,
            imports: [ConfigModule],
            inject: [ConfigService],
            useFactory: (config: ConfigService) => ({
                secret: config.get<string>("JWT_SECRET") ?? "dev-secret-change-me",
                signOptions: {
                    expiresIn: (config.get<string>("JWT_EXPIRES") ?? "1d") as any,
                },
            }),
        }),
    ],
    controllers: [AuthController],
    providers: [AuthService],
})
export class AuthModule {}
