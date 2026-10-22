# Phase 2: tin tức + carousel

Spec: `spec/01-news.md` · Phụ thuộc: phase 0 · Chỉ hiện ở màn hình **bệnh nhân** (Q3)

## Backend

### B2.1 Module `backend/src/news/` (mới)
- `news.entity.ts`: `NewsEntity` (`news`): `id`, `title` varchar(200), `url` varchar(2000), `imagePath` varchar, `createdAt` (`@CreateDateColumn`).
- `dto/create-news.dto.ts`: `title` (`@IsString() @IsNotEmpty() @MaxLength(200)`), `url` (`@IsUrl({ protocols: ['http','https'], require_protocol: true })`).
- `news.service.ts`: `list(limit?)` (`order: { createdAt: 'DESC' }`, `take: limit`), `create(dto, imagePath)`, `remove(id)` (không thấy thì 404, xoá bản ghi rồi `removeUpload(imagePath)`).
- `news.controller.ts`:
  - `GET /news?limit=` không gắn `@Roles` (mọi user đã login đều đọc được). `limit` dùng `ParseIntPipe` optional, chặn tối đa 50.
  - `POST /news` `@Roles('admin')`, `FileInterceptor('image', imageUpload('news'))`. Thiếu file thì 400. Lỗi thì `removeUpload`.
  - `DELETE /news/:id` `@Roles('admin')`.
- Response trả thẳng entity (`imagePath`), Flutter ghép URL qua `imageUrl()`.

### B2.2 Đăng ký
- `app.module.ts`: import `NewsModule`.
- `data-source.ts`: thêm `NewsEntity`.
- Migration `CreateNews`, rồi chạy `npm run typeorm migration:run`.
- `reset-db.ts`: thêm `news` vào câu TRUNCATE. File trong `uploads/` không bị xoá theo (chấp nhận, ghi chú `ponytail:`).

## Frontend

### F2.1 Dữ liệu
- `models/news.dart` (`id`, `title`, `url`, `imagePath`, `createdAt`).
- `services/news_service.dart`: `list({int? limit})`, `create(title, url, XFile image)` (FormData), `delete(id)`.
- `providers/admin_provider.dart`: thêm `news`, `loadNews()`, `addNews()`, `deleteNews()`.

### F2.2 Mở link
- `pubspec.yaml`: thêm `url_launcher`.
- iOS `Info.plist`: `LSApplicationQueriesSchemes` gồm `https`, `http`. Android `AndroidManifest.xml`: `<queries>` intent `VIEW` scheme `https`.
- Helper `openExternal(String url)` trong `core/ui.dart`: `launchUrl(..., mode: LaunchMode.externalApplication)`, thất bại thì hiện SnackBar.

### F2.3 Bệnh nhân (`patient_home_screen.dart`)
- `NewsCarousel` (widget trong `core/ui.dart` hoặc file riêng `widgets/news_carousel.dart` nếu dài):
  - `PageView.builder` cao 180, bo góc, `Image.network(fit: cover, errorBuilder: icon placeholder)`, tiêu đề trắng trên gradient đen ở đáy.
  - Chấm chỉ trang. `Timer.periodic(5s)` gọi `animateToPage`, huỷ trong `dispose`. Chỉ có 1 tin thì không chạy timer.
  - Bấm vào thì gọi `openExternal(url)`.
- Danh sách "Tin tức" bên dưới: `ListTile` với ảnh 64×64 và tiêu đề tối đa 2 dòng.
- Load bằng 1 lời gọi `list()` rồi lấy `take(5)` cho carousel (không gọi API 2 lần). Rỗng hoặc lỗi thì ẩn cả hai khối.

### F2.4 Admin (`admin_home_screen.dart`)
- Thêm mục/tab "Tin tức": danh sách tin, mỗi tin có nút xoá (hỏi lại bằng dialog). FAB "+" mở form (tiêu đề, link, chọn ảnh có preview). Nút "Lưu" chỉ bật khi đủ 3 trường.

## Kiểm tra
- [ ] Smoke: admin `POST /news` có ảnh trả 201. Patient **và doctor** `POST /news` trả 403. `url=javascript:alert(1)` trả 400. Thiếu ảnh trả 400. File `.pdf` hoặc ảnh > 2 MB trả 400 và không có file rác. `DELETE` xong thì file ảnh biến mất.
- [ ] Tay: ảnh tin bị lỗi/không tải được thì hiện placeholder, không crash.
- [ ] `GET /news?limit=5` trả tối đa 5 tin, mới nhất ở đầu.
- [ ] Tay: admin thêm tin, bệnh nhân refresh thấy tin ở đầu carousel, bấm vào mở trình duyệt ngoài. Không có tin thì không thấy khung rỗng.
- [ ] `npm run lint`, `npm test`, `flutter analyze` sạch.
