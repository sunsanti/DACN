import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from "typeorm";

/** Tin tức sức khoẻ / bệnh viện: link bài báo ngoài + ảnh đại diện (admin nhập). */
@Entity("news")
export class NewsEntity {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ type: "varchar", length: 200 })
    title: string;

    @Column({ type: "varchar", length: 2000 })
    url: string;

    @Column()
    imagePath: string; // /uploads/news/<uuid>.jpg

    @CreateDateColumn()
    createdAt: Date;
}
