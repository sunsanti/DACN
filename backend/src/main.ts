import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express'; // 🌟 THÊM MỚI: Thư viện quản lý app Express
import { join } from 'path'; // 🌟 THÊM MỚI: Thư viện xử lý đường dẫn file tĩnh

async function bootstrap() {
  // 🌟 SỬA DÒNG NÀY: Ép kiểu <NestExpressApplication> để NestJS hiểu các hàm static assets
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // 🌟 THÊM ĐOẠN NÀY: Mở khóa thư mục 'uploads' để ai cũng có thể tải file PDF
  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads/',
  });

  // 🌟 THÊM ĐOẠN NÀY: Cho phép app Flutter gọi API mà không bị chặn bảo mật chéo (CORS)
  app.enableCors();

  // 📝 GIỮ NGUYÊN: Cấu hình Swagger cũ của Quý
  const config = new DocumentBuilder()
    .setTitle('My API')
    .setDescription('API description')
    .setVersion('1.0')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  // 📝 GIỮ NGUYÊN: Lắng nghe cổng 3000 trên toàn mạng '0.0.0.0' rất chuẩn của Quý
  await app.listen(3000, '0.0.0.0');
  console.log(`🚀 Server đã mở khóa file tĩnh và đang chạy tại: http://192.168.56.1:3000`);
}
bootstrap();