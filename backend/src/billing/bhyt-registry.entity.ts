import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

/** Danh bạ BHYT có sẵn (đóng vai dữ liệu BHXH). Chỉ đọc: seed trong migration, không có API ghi. */
@Entity("bhyt_registry")
export class BhytRegistryEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ type: "varchar", length: 12, unique: true })
    cccd: string;

    @Column({ type: "varchar", length: 15, unique: true })
    cardNumber: string;

    @Column()
    fullName: string;

    @Column({ type: "date" })
    birthDate: string; // yyyy-MM-dd

    @Column({ type: "date" })
    validFrom: string;

    @Column({ type: "date" })
    validTo: string;
}
