import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";

@Module({
    imports: [TypeOrmModule.forRoot({
        type: 'postgres',
        host: 'localhost',
        port: 5432,
        username: 'postgres',
        password: '123456',
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        database: 'dacn_db',
        synchronize: false,
        logger: 'advanced-console',
        autoLoadEntities: true
    })],
    exports: [TypeOrmModule]
})
export class DatabaseModule {}