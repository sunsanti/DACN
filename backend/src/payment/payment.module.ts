import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { AppointmentEntity } from "../patient/entities/appointment.entity";
import { NotificationEntity } from "./notification.entity";
import { PaymentTransactionEntity } from "./payment-transaction.entity";
import { PaymentController } from "./payment.controller";
import { PaymentService } from "./payment.service";

@Module({
    imports: [TypeOrmModule.forFeature([AppointmentEntity, NotificationEntity, PaymentTransactionEntity])],
    controllers: [PaymentController],
    providers: [PaymentService],
})
export class PaymentModule {}
