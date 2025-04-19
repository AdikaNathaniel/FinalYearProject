import { Test, TestingModule } from '@nestjs/testing';
import { HealthAnalyticsService } from './health-analytics.service';

describe('HealthAnalyticsService', () => {
  let service: HealthAnalyticsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [HealthAnalyticsService],
    }).compile();

    service = module.get<HealthAnalyticsService>(HealthAnalyticsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
