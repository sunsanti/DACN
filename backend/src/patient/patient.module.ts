import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PatientController } from './patient.controller';
import { PatientService } from './patient.service';
import { PatientEntity } from './entities/patient.entity';
import { AppointmentEntity } from './entities/appointment.entity';
import { DoctorEntity } from '../doctor/entities/doctor.entity'; // 1. Bắt buộc phải import đường dẫn này

@Module({
  imports: [
    // 2. Chú ý: Bỏ DoctorEntity vào BÊN TRONG mảng của forFeature, KHÔNG bỏ ra ngoài
    TypeOrmModule.forFeature([
      PatientEntity, 
      AppointmentEntity, 
      DoctorEntity 
    ])
  ],
  controllers: [PatientController],
  providers: [PatientService],
})
export class PatientModule {}