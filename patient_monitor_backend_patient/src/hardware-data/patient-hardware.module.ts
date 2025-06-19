import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HealthDataController } from './patient-hardware.controller';
import { HealthDataService } from './patient-hardware.service';
import { HealthData, HealthDataSchema } from 'src/shared/schema/health-data.schema';
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HealthData.name, schema: HealthDataSchema }
    ]),
     HttpModule
  ],
  controllers: [HealthDataController],
  providers: [HealthDataService],
})
export class HealthDataModule {}