import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SmsService } from './sms.service';
import { SmsScheduler } from './sms.scheduler';
import { MedicationReminderController } from './medication-tracking/medication-reminder.controller';
import {
  SmsRecord,
  SmsRecordSchema,
} from 'src/shared/schema/sms.schema';
import {
  Appointment,
  AppointmentSchema,
} from 'src/shared/schema/appointments.schema';
import {
  NutritionProfile,
  NutritionProfileSchema,
} from 'src/shared/schema/nutrition.schema';
import {
  Medication,
  MedicationSchema,
} from 'src/shared/schema/medication.schema';
import {
  Pregnancy,
  PregnancySchema,
} from 'src/shared/schema/pregnancy.schema';
import {
  PendingReminder,
  PendingReminderSchema,
} from 'src/shared/schema/pending-reminder.schema';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SmsRecord.name, schema: SmsRecordSchema },
      { name: Appointment.name, schema: AppointmentSchema },
      { name: NutritionProfile.name, schema: NutritionProfileSchema },
      { name: Medication.name, schema: MedicationSchema },
      { name: Pregnancy.name, schema: PregnancySchema },
      { name: PendingReminder.name, schema: PendingReminderSchema }, // Add this line
    ]),
    HttpModule,
    ConfigModule,
    ScheduleModule.forRoot(),
  ],
  controllers: [MedicationReminderController],
  providers: [SmsService, SmsScheduler],
  exports: [SmsService],
})
export class SmsModule {}