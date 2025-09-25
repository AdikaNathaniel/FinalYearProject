import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VitalsHealthDataService } from './vitals-health-data.service';
import { VitalsHealthDataController } from './vitals-health-data.controller';
import { VitalsHealthData, VitalsHealthDataSchema } from 'src/shared/schema/vitals-health-data.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: VitalsHealthData.name, schema: VitalsHealthDataSchema }]),
  ],
  controllers: [VitalsHealthDataController],
  providers: [VitalsHealthDataService],
  exports: [VitalsHealthDataService],
})
export class VitalsHealthDataModule {}