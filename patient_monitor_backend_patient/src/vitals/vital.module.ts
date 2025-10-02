// src/vitals/vitals.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VitalsController } from './vitals.controller';
import { VitalsService } from './vitals.service';
import { Vital, VitalSchema } from 'src/shared/schema/vital.schema';
import { KafkaModule } from 'src/kafka/kafka.module'; // Add this import

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Vital.name, schema: VitalSchema }]),
    KafkaModule, 
  ],
  controllers: [VitalsController],
  providers: [VitalsService],
  exports: [VitalsService],
})
export class VitalsModule {}