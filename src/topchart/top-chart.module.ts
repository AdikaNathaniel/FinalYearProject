import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TopChartsController } from 'src/topchart/top-chart.controller';
import { TopChartsService } from 'src/topchart/top-chart.service';
import { TopChart, TopChartSchema } from 'src/shared/schema/top-chart.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: TopChart.name, schema: TopChartSchema }]),
  ],
  controllers: [TopChartsController],
  providers: [TopChartsService],
})
export class TopChartsModule {}