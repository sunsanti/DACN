import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PatientModule } from './patient/patient.module';
import { DoctorModule } from './doctor/doctor.module';
import { DatabaseModule } from './database/database.module';

@Module({
  imports: [PatientModule, DoctorModule,DatabaseModule],
  controllers: [AppController],
  providers: [AppService],
})


export class AppModule {}
