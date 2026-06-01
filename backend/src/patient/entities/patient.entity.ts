import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from "typeorm";
import { AppointmentEntity } from "./appointment.entity";

@Entity('patient')
export class PatientEntity {

    @PrimaryGeneratedColumn()
    id!: number;

    @Column()
    name!: string;

    @Column()
    gender!: string;

    @Column()
    age!: number;

    @Column({ name: 'birthDate', type: 'timestamp' })
    birthDate!: Date;

    @Column()
    email!: string;

    @Column()
    phone!: string;

    @Column()
    address!: string;

    @Column({ name: 'createdAt', type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
    createdAt!: Date;

    @Column({ nullable: true })
    avatar!: string;

    @Column({ nullable: true })
    cccd!: string;

    @Column({ nullable: true })
    bhyt!: string;

    @OneToMany(() => AppointmentEntity, (appointment) => appointment.patient)
    appointments!: AppointmentEntity[];

    // Thêm dòng này vào dưới các cột cũ của Quý
    @Column({ type: 'varchar', length: 255, nullable: true })
    password!: string;
}