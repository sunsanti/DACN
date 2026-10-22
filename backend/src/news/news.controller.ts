import {
    BadRequestException,
    Body,
    Controller,
    DefaultValuePipe,
    Delete,
    Get,
    Param,
    ParseIntPipe,
    Post,
    Query,
    UploadedFile,
    UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ApiBearerAuth, ApiConsumes, ApiTags } from "@nestjs/swagger";
import { NewsService } from "./news.service";
import { CreateNewsDTO } from "./news.dto";
import { Roles } from "../common/decorators/roles.decorator";
import { CleanupUploadOnError, imageUpload, toPublicPath } from "../common/upload";

@ApiTags("news")
@ApiBearerAuth()
@Controller("news")
export class NewsController {
    constructor(private readonly newsService: NewsService) {}

    /** Mọi user đã login. Mới nhất trước; `limit` tối đa 50. */
    @Get()
    list(@Query("limit", new DefaultValuePipe(50), ParseIntPipe) limit: number) {
        return this.newsService.list(Math.min(Math.max(limit, 1), 50));
    }

    /** multipart: title, url, image (bắt buộc). */
    @Roles("admin")
    @Post()
    @ApiConsumes("multipart/form-data")
    @UseInterceptors(FileInterceptor("image", imageUpload("news")), CleanupUploadOnError)
    create(@Body() dto: CreateNewsDTO, @UploadedFile() image?: Express.Multer.File) {
        if (!image) throw new BadRequestException("Tin tức phải có ảnh đại diện");
        return this.newsService.create(dto, toPublicPath(image));
    }

    @Roles("admin")
    @Delete(":id")
    remove(@Param("id", ParseIntPipe) id: number) {
        return this.newsService.remove(id);
    }
}
