import {
    BadRequestException,
    CallHandler,
    ExecutionContext,
    Injectable,
    NestInterceptor,
} from "@nestjs/common";
import type { MulterOptions } from "@nestjs/platform-express/multer/interfaces/multer-options.interface";
import { randomUUID } from "crypto";
import { mkdirSync, promises as fs } from "fs";
import { diskStorage } from "multer";
import { join } from "path";
import { Observable, catchError, from, mergeMap, throwError } from "rxjs";

/** Thư mục gốc chứa ảnh upload, được serve tại `/uploads` (xem main.ts). */
export const UPLOAD_ROOT = join(process.cwd(), "uploads");

const EXT: Record<string, string> = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
};

/** Multer options cho ảnh: chỉ jpeg/png/webp, ≤ 2MB, tên file UUID (không dùng originalname). */
export function imageUpload(subdir: "avatars" | "news"): MulterOptions {
    const dir = join(UPLOAD_ROOT, subdir);
    mkdirSync(dir, { recursive: true });
    return {
        storage: diskStorage({
            destination: dir,
            filename: (_req, file, cb) => cb(null, randomUUID() + EXT[file.mimetype]),
        }),
        fileFilter: (_req, file, cb) =>
            EXT[file.mimetype]
                ? cb(null, true)
                : cb(new BadRequestException("Chỉ nhận ảnh JPG/PNG/WEBP"), false),
        limits: { fileSize: 2 * 1024 * 1024 },
    };
}

/** `/uploads/<subdir>/<file>` hoặc `''` nếu không có file. */
export function toPublicPath(file?: Express.Multer.File): string {
    if (!file) return "";
    const subdir = file.destination.split(/[\\/]/).pop();
    return `/uploads/${subdir}/${file.filename}`;
}

/** Xoá file theo public path. Bỏ qua path lạ và file không tồn tại. */
export async function removeUpload(publicPath?: string | null): Promise<void> {
    if (!publicPath || !publicPath.startsWith("/uploads/") || publicPath.includes("..")) return;
    await fs.unlink(join(UPLOAD_ROOT, publicPath.slice("/uploads/".length))).catch(() => undefined);
}

/**
 * Đặt SAU FileInterceptor: nếu validate DTO hoặc handler lỗi thì xoá file vừa upload,
 * tránh để lại file rác. (Pipes chạy bên trong next.handle() nên lỗi DTO cũng bị bắt.)
 */
@Injectable()
export class CleanupUploadOnError implements NestInterceptor {
    intercept(ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
        const file = ctx.switchToHttp().getRequest<{ file?: Express.Multer.File }>().file;
        return next.handle().pipe(
            catchError((err: unknown) =>
                from(removeUpload(toPublicPath(file))).pipe(mergeMap(() => throwError(() => err))),
            ),
        );
    }
}
