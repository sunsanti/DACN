import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { AppointmentEntity } from "../patient/entities/appointment.entity";

/** Every SePay webhook we accepted (dedup by sepayId; audit trail for mismatches). */
@Entity("payment_transaction")
export class PaymentTransactionEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ type: "bigint", unique: true })
    sepayId: string; // bigint comes back as string

    @ManyToOne(() => AppointmentEntity, { nullable: true, onDelete: "SET NULL" })
    appointment: AppointmentEntity | null;

    @Column({ type: "int" })
    amount: number;

    @Column({ type: "text" })
    content: string;

    @Column()
    matched: boolean;

    @CreateDateColumn()
    createdAt: Date;
}
