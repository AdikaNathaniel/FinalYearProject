import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { TerminusModule } from '@nestjs/terminus';
import { MulterModule } from '@nestjs/platform-express';
import * as Joi from 'joi';

// Controllers
import { AppController } from './application.controller';
import { SmsController } from './sms/sms.controller';
import { MedicationReminderController } from './sms/medication-tracking/medication-reminder.controller';

// Services
import { AppService } from './app.service';
import { SmsService } from './sms/sms.service';
import { SmsScheduler } from './sms/sms.scheduler';
import { MobileAppSyncService } from './sms/mobile-app-sync.service';
import { AppointmentsCronService } from './doctors/appointment.cron';
import { AppwriteService } from './appwrite.service';
import { AgoraService } from './agora.service';

// Modules
import { VideoModule } from './video-call/video.module';
import { DoctorsModule } from './doctors/doctors.module';
import { SearchModule } from './search/search.module';
import { SharedModule } from './doctors/shared.module';
import { TasksModule } from './doctors/task.module';
import { PatientModule } from './patient/patient.module';
import { VisitModule } from './visit/visit.module';
import { UsersModule } from './users/users.module';
import { OrderModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { StripeModule } from './payments/stripe.module';
import { TrackingModule } from 'src/tracking/tracking.module';
import { FaceRecognitionModule } from 'src/facial-recognition/facial-recognition.module';
import { AppointmentsModule } from 'src/appointments/appointment.module';
import { HealthModule } from 'src/health/health.module';
import { PrescriptionsModule } from 'src/prescriptions/prescription.module';
import { SmsModule } from './sms/sms.module';
import { ChatbotModule } from './chat/chat.module';
import { EmailModule } from 'src/email/email.module';
import { NotificationModule } from 'src/notification/notification.module';
import { ReportModule } from './report/report.module';
import { ChatRealTimeModule } from './chat-real-time/chat-real-time.module';
import { EmergencyModule } from './emergency/emergency.module';
import { HttpModules } from 'src/shared/http/http.module';
import { PinModule } from './pin/pin.module';
import { MedicsModule } from './medic/medics.module';
import { FaceAuthModule } from './face-auth/face-auth.module';
import { AuthModule } from './auth/auth.module';
import { SupportModule } from './support/support.module';
import {  SymptomsModule } from './symptom/symptom.module';
import { VitalsModule } from './vitals/vital.module';
import { KafkaModule } from './kafka/kafka.module';
// import { HealthDataModule } from './hardware-data/patient-hardware.module';

// Schemas - ONLY FOR SCHEMAS USED DIRECTLY IN APP MODULE
import { Chat, ChatSchema } from 'src/shared/schema/chat.schema';
import { SmsRecord, SmsRecordSchema } from 'src/shared/schema/sms.schema';
import { Appointment, AppointmentSchema } from 'src/shared/schema/appointments.schema';
import { NutritionProfile, NutritionProfileSchema } from 'src/shared/schema/nutrition.schema';
import { Medication, MedicationSchema } from 'src/shared/schema/medication.schema';
import { Pregnancy, PregnancySchema } from 'src/shared/schema/pregnancy.schema';
import { PendingReminder, PendingReminderSchema } from 'src/shared/schema/pending-reminder.schema';
import { OfflineReminder, OfflineReminderSchema } from 'src/shared/schema/offline-reminder.schema';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: Joi.object({
        MONGODB_URI: Joi.string().required(),
        FRONTEND_URL: Joi.string().required(),
        // You can add more validation rules from the original config as needed
      }),
    }),
    
    // Database
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI'),
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
    
    // File Upload
    MulterModule.register({ dest: './uploads' }),
    
    // Health Check
    TerminusModule,
    
    // Feature Modules
    SymptomsModule,
    VideoModule,
    PatientModule,
    VisitModule,
    UsersModule,
    OrderModule,
    FaceRecognitionModule,
    PaymentsModule,
    MedicsModule,
    FaceAuthModule,
    AuthModule,
    AppointmentsModule,
    StripeModule,
    VitalsModule,
    KafkaModule,
    SupportModule,
    // HealthDataModule,
    PrescriptionsModule,
    HealthModule,
    DoctorsModule,
    TrackingModule,
    EmergencyModule,
    HttpModules,
    SmsModule,
    ReportModule,
    ChatbotModule,
    EmailModule,
    NotificationModule,  // This module already registers the Notification schema
    ChatRealTimeModule,
    SharedModule,
    TasksModule,
    PinModule,
    SearchModule,
    
    // Schemas - Only register schemas that are used directly in THIS module's services
    // DO NOT register schemas that are already registered in their respective feature modules
    MongooseModule.forFeature([
      { name: Chat.name, schema: ChatSchema },
      { name: SmsRecord.name, schema: SmsRecordSchema },
      { name: Appointment.name, schema: AppointmentSchema },
      { name: NutritionProfile.name, schema: NutritionProfileSchema },
      { name: Medication.name, schema: MedicationSchema },
      { name: Pregnancy.name, schema: PregnancySchema },
      { name: PendingReminder.name, schema: PendingReminderSchema },
      { name: OfflineReminder.name, schema: OfflineReminderSchema },
      // Removed Notification schema because it's already registered in NotificationModule
    ]),
  ],
  controllers: [
    AppController,
    MedicationReminderController, 
    SmsController
  ],
  providers: [
    AppService,
    SmsService,
    SmsScheduler,
    MobileAppSyncService,
    AppointmentsCronService,
    AppwriteService,
    AgoraService
  ],
  exports: [
    SmsService,
    MobileAppSyncService,
    AppwriteService,
    AgoraService
  ],
})
export class AppModule {}