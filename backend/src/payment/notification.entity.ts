import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from "typeorm";

/** Admin inbox (shared by all admins): payments received, mismatched transfers. */
@Entity("notification")
export class NotificationEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    title: string;

    @Column({ type: "text" })
    body: string;

    @Column({ type: "int", nullable: true })
    appointmentId: number | null;

    @Column({ type: "timestamp", nullable: true })
    readAt: Date | null;

    @CreateDateColumn()
    createdAt: Date;
}
