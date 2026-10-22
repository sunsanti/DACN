# 01. Tin tức sức khoẻ / bệnh viện

## Mục tiêu

> Chốt Q3: tin tức **chỉ hiện ở màn hình bệnh nhân** (bác sĩ không thấy).

Admin dán link bài báo (sức khoẻ, thông báo bệnh viện) kèm tiêu đề và ảnh đại diện. Trang chủ bệnh nhân có:
- **Carousel** ở đầu trang: 5 tin mới nhất.
- **Mục "Tin tức"** bên dưới: danh sách toàn bộ tin, mới nhất ở trên.

Bấm vào một tin thì mở link bằng trình duyệt ngoài. App **không** cào nội dung bài báo.

## Backend

### Entity `NewsEntity` (bảng `news`), module mới `src/news/`

| Cột | Kiểu | Ghi chú |
|-----|------|---------|
| `id` | serial PK | |
| `title` | varchar(200) NOT NULL | |
| `url` | varchar(2000) NOT NULL | chỉ `http://` hoặc `https://` |
| `imagePath` | varchar NOT NULL | ví dụ `/uploads/news/<uuid>.jpg` |
| `createdAt` | timestamp, `@CreateDateColumn` | dùng để sắp xếp |

Migration `CreateNews`. Thêm entity vào `data-source.ts`.

### API

| Method | Route | Quyền | Mô tả |
|--------|-------|-------|-------|
| GET | `/news` | mọi user đã login | Danh sách tin, `ORDER BY createdAt DESC`. Query `?limit=` tuỳ chọn (carousel gọi `limit=5`) |
| POST | `/news` | `admin` | `multipart/form-data`: `title`, `url`, `image` (file, bắt buộc) |
| DELETE | `/news/:id` | `admin` | Xoá bản ghi **và** file ảnh |

Response của một item:
```json
{ "id": 1, "title": "…", "url": "https://…", "imageUrl": "/uploads/news/….jpg", "createdAt": "…" }
```

### Validation
- `title`: `@IsString() @MaxLength(200)`, không rỗng.
- `url`: `@IsUrl({ protocols: ['http','https'], require_protocol: true })`. Chặn `javascript:` và `file:`.
- `image`: theo ràng buộc chung trong README. Thiếu ảnh thì trả 400.
- Sửa tin: **không làm**. Muốn sửa thì xoá rồi tạo lại.

## Frontend

### Bệnh nhân (`patient_home_screen.dart`)
- `NewsCarousel`: `PageView` cao khoảng 180, mỗi trang là ảnh phủ kín kèm tiêu đề trên dải gradient ở đáy. Có chấm chỉ trang. Tự chuyển trang mỗi 5 giây bằng `Timer.periodic` và huỷ timer trong `dispose`.
- Danh sách "Tin tức": `ListTile` với thumbnail 64×64 bên trái và tiêu đề bên phải.
- Bấm vào tin: `launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)`.
- Không có tin nào thì ẩn cả carousel và mục tin tức (không hiện khung rỗng).
- Ảnh lỗi thì dùng `errorBuilder` hiện icon placeholder.

### Admin (`admin_home_screen.dart`, thêm tab/mục "Tin tức")
- Danh sách tin, mỗi tin có nút xoá (xác nhận bằng dialog trước khi xoá).
- Nút "+": form gồm tiêu đề, link, chọn ảnh (preview ngay sau khi chọn). Chỉ cho bấm "Lưu" khi đủ cả 3 trường.

### Code
- `models/news.dart`, `services/news_service.dart`. State để trong `AdminProvider` cho phía admin. Phía bệnh nhân load trực tiếp trong màn hình, không cần provider riêng.
- Thêm `url_launcher` vào `pubspec.yaml`. iOS cần `LSApplicationQueriesSchemes` (`https`) trong `Info.plist`, Android cần `<queries>` intent VIEW https.

## Tiêu chí nghiệm thu
- [ ] Admin tạo tin có ảnh, tin hiện ngay đầu carousel của bệnh nhân.
- [ ] Tạo tin với `url = javascript:alert(1)` thì nhận 400.
- [ ] Upload file `.pdf` hoặc ảnh > 2 MB thì nhận 400, và không có file rác trong `uploads/news/`.
- [ ] Bệnh nhân hoặc bác sĩ gọi `POST /news` thì nhận 403.
- [ ] Xoá tin thì file ảnh trong `uploads/news/` cũng bị xoá.
- [ ] Bấm tin thì mở trình duyệt ngoài, đúng link.
