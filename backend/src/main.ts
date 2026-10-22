import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { NestExpressApplication } from '@nestjs/platform-express';
import { UPLOAD_ROOT } from './common/upload';

import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Behind ngrok the agent connects from localhost: trust X-Forwarded-For only from loopback,
  // so req.ip (rate limit on /auth/bhyt-lookup) is the real client, and LAN clients can't spoof it.
  app.set('trust proxy', 'loopback');

  // Allow the Flutter web build (and any dev origin) to call the API.
  app.enableCors();

  // Ảnh upload (avatar, tin tức). Public, tên file UUID; không dùng cho dữ liệu y tế.
  // Đặt SAU enableCors để Flutter web (CanvasKit tải ảnh bằng fetch) nhận được header CORS.
  app.useStaticAssets(UPLOAD_ROOT, { prefix: '/uploads' });

  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const config = new DocumentBuilder()
    .setTitle('My API')
    .setDescription('API description')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  // Bind all IPv4 interfaces so the Android emulator (10.0.2.2) and LAN devices can reach it.
  await app.listen(3000, '0.0.0.0');
}
bootstrap();