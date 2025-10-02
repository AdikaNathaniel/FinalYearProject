import { Test, TestingModule } from '@nestjs/testing';
import { HealthAnalyticsController } from './health-analytics.controller';

describe('HealthAnalyticsController', () => {
  let controller: HealthAnalyticsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthAnalyticsController],
    }).compile();

    controller = module.get<HealthAnalyticsController>(HealthAnalyticsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
