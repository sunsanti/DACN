import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { NewsEntity } from "./news.entity";
import { CreateNewsDTO } from "./news.dto";
import { removeUpload } from "../common/upload";

@Injectable()
export class NewsService {
    constructor(@InjectRepository(NewsEntity) private readonly repo: Repository<NewsEntity>) {}

    list(limit?: number): Promise<NewsEntity[]> {
        return this.repo.find({ order: { createdAt: "DESC", id: "DESC" }, take: limit });
    }

    create(dto: CreateNewsDTO, imagePath: string): Promise<NewsEntity> {
        return this.repo.save({ title: dto.title, url: dto.url, imagePath });
    }

    async remove(id: number): Promise<void> {
        const news = await this.repo.findOne({ where: { id } });
        if (!news) throw new NotFoundException("Tin tức không tồn tại");
        await this.repo.delete(id);
        await removeUpload(news.imagePath);
    }
}
