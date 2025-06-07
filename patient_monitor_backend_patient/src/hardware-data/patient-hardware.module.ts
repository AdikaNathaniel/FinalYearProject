import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PatientHardwareService } from './patient-hardware.service';
import { PatientHardwareController } from './patient-hardware.controller';
import { PatientHardware, PatientHardwareSchema } from 'src/shared/schema/patient-hardware.schema';
import { PredictionHardware, PredictionHardwareSchema } from 'src/shared/schema/prediction-hardware.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PatientHardware.name, schema: PatientHardwareSchema },
      { name: PredictionHardware.name, schema: PredictionHardwareSchema }
    ])
  ],
  controllers: [PatientHardwareController],
  providers: [PatientHardwareService],
  exports: [PatientHardwareService],
})
export class PatientHardwareModule {}