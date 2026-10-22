import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";

@Module({
    imports: [
        TypeOrmModule.forRootAsync({
            imports: [ConfigModule],
            inject: [ConfigService],
            useFactory: (config: ConfigService) => ({
                type: "postgres",
                host: config.get<string>("DB_HOST", "localhost"),
                port: Number(config.get<string>("DB_PORT", "5432")),
                username: config.get<string>("DB_USER", "postgres"),
                password: config.get<string>("DB_PASSWORD", "123456"),
                database: config.get<string>("DB_NAME", "dacn_db"),
                entities: [__dirname + "/**/*.entity{.ts,.js}"],
                synchronize: false,
                logger: "advanced-console",
                autoLoadEntities: true,
                // DB session in the server's timezone, so `now()` defaults (createdAt…) match
                // the Asia/Ho_Chi_Minh wall clock Node uses for `timestamp` columns.
                extra: { options: "-c timezone=Asia/Ho_Chi_Minh" },
            }),
        }),
    ],
    exports: [TypeOrmModule],
})
export class DatabaseModule {}
