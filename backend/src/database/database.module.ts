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
            }),
        }),
    ],
    exports: [TypeOrmModule],
})
export class DatabaseModule {}
