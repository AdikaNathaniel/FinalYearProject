// src/modules/chart-data.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChartDataController } from './chart-data.controller';
import { ChartDataService } from './chart-data.service';
import { ChartData, ChartDataSchema } from 'src/shared/schema/chart-data.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ChartData.name, schema: ChartDataSchema },
    ]),
  ],
  controllers: [ChartDataController],
  providers: [ChartDataService],
  exports: [ChartDataService],
})
export class ChartDataModule {}