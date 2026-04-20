import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PatientModule } from './patient/patient.module';
import { DoctorModule } from './doctor/doctor.module';
import { AuthModule } from './auth/login/auth.module';
@Module({
  imports: [PatientModule, DoctorModule, AuthModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
