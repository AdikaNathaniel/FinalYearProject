// src/notification/notification.module.ts
import { Module } from '@nestjs/common';
import { NotificationController } from   './notification.controller';
import { NotificationService } from  './notification.service';
import { MongooseModule } from '@nestjs/mongoose';
import { Notification, NotificationSchema } from 'src/shared/schema/notification.schema';
import { SmsNotificationService } from './sms-notification.service';
import { NotificationSchedulerService } from  './notification-scheduler.service';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot(),
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
    ]),
  ],
  controllers: [NotificationController],
  providers: [
    NotificationService,
    SmsNotificationService,
    NotificationSchedulerService,
  ],
  exports: [NotificationService],
})
export class NotificationModule {}