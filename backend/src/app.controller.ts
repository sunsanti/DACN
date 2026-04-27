import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { ApiTags } from '@nestjs/swagger';
import { DataSource } from 'typeorm';

@ApiTags('test-db')
@Controller()
export class AppController {
  constructor
  (
    private readonly appService: AppService,
    private dataSource: DataSource
  ) {}

  @Get('/hello')
  getHello(): string {
    return this.appService.getHello();
  }
  @Get('db-check')
  async checkDB(){
    const isConnected = this.dataSource.isInitialized;
    console.log(this.dataSource.options);
        return {
            connected: isConnected,
            database: this.dataSource.options.database,
            host: (this.dataSource.options as any).host,
        };
  }
}
