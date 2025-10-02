import { Module } from '@nestjs/common';
import { HealthAnalyticsService } from './health-analytics.service';
import { HealthAnalyticsController } from './health-analytics.controller';

@Module({
  providers: [HealthAnalyticsService],
  controllers: [HealthAnalyticsController]
})
export class HealthAnalyticsModule {}
