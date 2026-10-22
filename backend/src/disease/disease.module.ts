import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { DiseaseEntity } from "./disease.entity";
import { DiseaseController } from "./disease.controller";
import { DiseaseService } from "./disease.service";

@Module({
    imports: [TypeOrmModule.forFeature([DiseaseEntity])],
    controllers: [DiseaseController],
    providers: [DiseaseService],
    exports: [DiseaseService, TypeOrmModule], // DoctorModule dùng khi hoàn thành khám
})
export class DiseaseModule {}
