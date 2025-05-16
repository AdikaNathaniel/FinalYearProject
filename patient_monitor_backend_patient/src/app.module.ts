import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import config from 'config';
import { UsersModule } from './users/users.module';
import { OrderModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { StripeModule } from './payments/stripe.module';
import { TrackingModule } from 'src/tracking/tracking.module';
import { AppointmentsModule } from 'src/appointments/appointment.module';
import { HealthModule } from 'src/health/health.module';
import { PrescriptionsModule } from 'src/prescriptions/prescription.module';
import { SmsModule } from './sms/sms.module';
// Import ChatModule and Chat schema
import { Chat, ChatSchema } from 'src/shared/schema/chat.schema';
import { ChatbotModule } from './chat/chat.module';
// Import EmailModule and NotificationModule
import { EmailModule } from 'src/email/email.module'; // Adjust the path as necessary
import { NotificationModule } from 'src/notification/notification.module';
import { ReportModule } from './report/report.module';
import { ChatRealTimeModule } from './chat-real-time/chat-real-time.module';

@Module({
  imports: [
    MongooseModule.forRoot(config.get('mongoDbUrl'), {
      w: 1,
      retryWrites: true,
      maxPoolSize: 10,
    }),
    UsersModule,
    // ElasticsearchConfigModule,
    OrderModule,
    PaymentsModule,
    AppointmentsModule,
    StripeModule,
    PrescriptionsModule,
    HealthModule,
    TrackingModule,
    SmsModule,
    ReportModule,
    ChatbotModule, // Add ChatModule here
    MongooseModule.forFeature([{ name: Chat.name, schema: ChatSchema }]), // Add Chat Schema if needed
    EmailModule, // Add EmailModule here
    // eslint-disable-next-line prettier/prettier
    NotificationModule, ChatRealTimeModule, // Add NotificationModule here
  ],
  controllers: [AppController], // Add DeliveryController
  providers: [AppService], // Add DeliveryService and MQService
})
export class AppModule {}
