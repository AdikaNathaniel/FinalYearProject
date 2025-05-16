import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ScheduleModule } from '@nestjs/schedule';
import { MongooseModule } from '@nestjs/mongoose';
import { SmsService } from './sms.service';
import { SmsScheduler } from './sms.scheduler';
import { SmsController } from './sms.controller';
import { SmsRecord, SmsRecordSchema } from '../shared/schema/sms.schema';
import { Appointment, AppointmentSchema } from '../shared/schema/appointments.schema';
import { NutritionProfile, NutritionProfileSchema } from '../shared/schema/nutrition.schema';
import { Medication, MedicationSchema } from '../shared/schema/medication.schema';
import { Pregnancy, PregnancySchema } from '../shared/schema/pregnancy.schema';

@Module({
  imports: [
    HttpModule, // 
    ScheduleModule.forRoot(),
    MongooseModule.forFeature([
      { name: SmsRecord.name, schema: SmsRecordSchema },
      { name: Appointment.name, schema: AppointmentSchema },
      { name: NutritionProfile.name, schema: NutritionProfileSchema },
      { name: Medication.name, schema: MedicationSchema },
      { name: Pregnancy.name, schema: PregnancySchema },
    ]),
  ],
  controllers: [SmsController],
  providers: [SmsService, SmsScheduler],
  exports: [SmsService],
})
export class SmsModule {}