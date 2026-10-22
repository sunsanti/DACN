# Phase 0: nền upload ảnh

Mục tiêu: một chỗ duy nhất xử lý upload ảnh để phase 1, 2 dùng chung.

## Backend

### B0.1 `backend/src/common/upload.ts` (mới)
- `imageUpload(subdir: 'avatars' | 'news')` trả về `MulterOptions`:
  - `storage: diskStorage({ destination: uploads/<subdir> (tự mkdir recursive), filename: randomUUID() + extname theo mimetype })`. **Không** dùng `originalname`.
  - `fileFilter`: chỉ nhận `image/jpeg|png|webp`. Sai loại thì `cb(new BadRequestException('Chỉ nhận ảnh JPG/PNG/WEBP'), false)`.
  - `limits: { fileSize: 2 * 1024 * 1024 }`.
- `toPublicPath(file?: Express.Multer.File): string` trả `/uploads/<subdir>/<filename>`, hoặc `''` nếu không có file.
- `removeUpload(publicPath: string)`: `fs.promises.unlink`, nuốt lỗi ENOENT. Chỉ xoá path bắt đầu bằng `/uploads/`.
- Dùng: `@UseInterceptors(FileInterceptor('avatar', imageUpload('avatars')))`.

### B0.2 `backend/src/main.ts`
- `NestFactory.create<NestExpressApplication>(AppModule)`.
- `app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads' })`.

### B0.3 `.gitignore`
- Thêm `backend/uploads/`.

## Frontend

### F0.1 `frontend/lib/core/ui.dart`
- `String? imageUrl(String? path)` trả `null` nếu rỗng, ngược lại trả `ApiConfig.baseUrl + path`.
- `class UserAvatar extends StatelessWidget { String? avatarUrl; String name; double radius = 20; }`:
  - Có URL thì `CircleAvatar(backgroundImage: NetworkImage(...), onBackgroundImageError: ...)`, ảnh lỗi thì quay về chữ cái đầu.
  - Không có URL thì `CircleAvatar(child: Text(name[0].toUpperCase()))`. `name` rỗng thì dùng icon person.

## Kiểm tra
- [ ] Bỏ tay 1 file vào `backend/uploads/avatars/x.png`, `curl -I localhost:3000/uploads/avatars/x.png` trả 200 không cần token.
- [ ] `curl localhost:3000/uploads/../package.json` không đọc được file ngoài thư mục (express static đã chặn sẵn, chỉ cần xác nhận).
- [ ] `npm run lint` và `flutter analyze` sạch.
