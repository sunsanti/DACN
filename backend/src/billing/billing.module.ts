import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { BhytRegistryEntity } from "./bhyt-registry.entity";
import { BhytService } from "./bhyt.service";

@Module({
    imports: [TypeOrmModule.forFeature([BhytRegistryEntity])],
    providers: [BhytService],
    exports: [BhytService],
})
export class BillingModule {}
