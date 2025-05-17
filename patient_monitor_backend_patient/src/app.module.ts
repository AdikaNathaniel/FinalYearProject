import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { DoctorsModule } from './doctors/doctors.module';
import config from 'config';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsersModule } from './users/users.module';
import { OrderModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { StripeModule } from './payments/stripe.module';
import { TrackingModule } from 'src/tracking/tracking.module';
import { AppointmentsModule } from 'src/appointments/appointment.module';
import { HealthModule } from 'src/health/health.module';
import { PrescriptionsModule } from 'src/prescriptions/prescription.module';
import { SmsModule } from './sms/sms.module';
import { Chat, ChatSchema } from 'src/shared/schema/chat.schema';
import { ChatbotModule } from './chat/chat.module';
import { EmailModule } from 'src/email/email.module';
import { NotificationModule } from 'src/notification/notification.module';
import { ReportModule } from './report/report.module';
import { ChatRealTimeModule } from './chat-real-time/chat-real-time.module';

// SMS Related imports
import { SmsService } from './sms/sms.service';
import { SmsScheduler } from './sms/sms.scheduler';
import { MobileAppSyncService } from './sms/mobile-app-sync.service';
import { MedicationReminderController } from './sms/medication-tracking/medication-reminder.controller';
import { SmsRecord, SmsRecordSchema } from 'src/shared/schema/sms.schema';
import { Appointment, AppointmentSchema } from 'src/shared/schema/appointments.schema';
import { NutritionProfile, NutritionProfileSchema } from 'src/shared/schema/nutrition.schema';
import { Medication, MedicationSchema } from 'src/shared/schema/medication.schema';
import { Pregnancy, PregnancySchema } from 'src/shared/schema/pregnancy.schema';
import { PendingReminder, PendingReminderSchema } from 'src/shared/schema/pending-reminder.schema';
import { OfflineReminder, OfflineReminderSchema } from 'src/shared/schema/offline-reminder.schema';
import { SmsController } from './sms/sms.controller';



@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
        load: [() => config]
    }),
    SmsModule,
    
    // Database
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI') || config.get('mongoDbUrl'),
        w: 1,
        retryWrites: true,
        maxPoolSize: 10,
      }),
      inject: [ConfigService],
    }),
    
    // HTTP Client
    HttpModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        timeout: configService.get('HTTP_TIMEOUT') || 5000,
        maxRedirects: configService.get('HTTP_MAX_REDIRECTS') || 5,
      }),
      inject: [ConfigService],
    }),
    
    // Scheduled Tasks
    ScheduleModule.forRoot(),
    
    // Feature Modules
    UsersModule,
    OrderModule,
    PaymentsModule,
    AppointmentsModule,
    StripeModule,
    PrescriptionsModule,
    HealthModule,
    DoctorsModule,
    TrackingModule,
    SmsModule,
    ReportModule,
    ChatbotModule,
    EmailModule,
    NotificationModule, 
    ChatRealTimeModule,
    
    // Schemas
    MongooseModule.forFeature([
      { name: Chat.name, schema: ChatSchema },
      { name: SmsRecord.name, schema: SmsRecordSchema },
      { name: Appointment.name, schema: AppointmentSchema },
      { name: NutritionProfile.name, schema: NutritionProfileSchema },
      { name: Medication.name, schema: MedicationSchema },
      { name: Pregnancy.name, schema: PregnancySchema },
      { name: PendingReminder.name, schema: PendingReminderSchema },
      { name: OfflineReminder.name, schema: OfflineReminderSchema },
    ]),
  ],
  controllers: [
    AppController,
    MedicationReminderController, 
    SmsController
  ],
  providers: [
    AppService,
    SmsService, // Add SMS service
    SmsScheduler, // Add scheduler for daily reminders
    MobileAppSyncService, // Add mobile sync service
  ],
  exports: [
    SmsService,
    MobileAppSyncService,
  ],
})
export class AppModule {}