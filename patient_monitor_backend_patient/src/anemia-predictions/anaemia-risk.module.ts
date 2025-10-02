import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AnaemiaRiskController } from './anaemia-risk.controller';
import { AnaemiaRiskService } from './anaemia-risk.service';
import { RiskAssessment, RiskAssessmentSchema } from 'src/shared/schema/risk-assessment.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: RiskAssessment.name, schema: RiskAssessmentSchema },
    ]),
  ],
  controllers: [AnaemiaRiskController],
  providers: [AnaemiaRiskService],
})
export class AnaemiaRiskModule {}