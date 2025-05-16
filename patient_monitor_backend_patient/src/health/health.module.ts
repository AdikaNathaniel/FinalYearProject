import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';
import { Health, HealthSchema } from 'src/shared/schema/health.schema';

@Module({
  imports: [MongooseModule.forFeature([{ name: Health.name, schema: HealthSchema }])],
  controllers: [HealthController],
  providers: [HealthService],
})
export class HealthModule {}
