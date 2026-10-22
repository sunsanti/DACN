import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

/** Bảng giá bệnh / dịch vụ do admin lập. Không xoá, chỉ tắt (active=false). */
@Entity("disease")
export class DiseaseEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ type: "varchar", length: 200, unique: true })
    name: string;

    @Column({ type: "int" })
    price: number; // VND

    @Column({ default: true })
    active: boolean;

    @Column({ default: true })
    bhytCovered: boolean; // dịch vụ được BHYT chi trả
}
