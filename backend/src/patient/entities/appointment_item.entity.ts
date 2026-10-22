import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { AppointmentEntity } from "./appointment.entity";

/** Một dòng hoá đơn: snapshot tên + giá bệnh lúc bác sĩ hoàn thành khám (không FK tới disease). */
@Entity("appointment_item")
export class AppointmentItemEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => AppointmentEntity, (a) => a.items, { onDelete: "CASCADE", nullable: false })
    appointment: AppointmentEntity;

    @Column({ type: "varchar", length: 200 })
    name: string;

    @Column({ type: "int" })
    price: number;

    @Column({ default: true })
    bhytCovered: boolean; // snapshot cờ BHYT của dịch vụ lúc khám
}
