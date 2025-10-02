// src/notification/notification-scheduler.service.ts
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { NotificationService } from './notification.service';
import { SmsNotificationService } from './sms-notification.service';

@Injectable()
export class NotificationSchedulerService implements OnModuleInit {
  private readonly logger = new Logger(NotificationSchedulerService.name);

  constructor(
    private readonly notificationService: NotificationService,
    private readonly smsService: SmsNotificationService,
  ) {}

  onModuleInit() {
    this.logger.log('Initializing pending notifications check');
    this.handleCron().catch((err) => {
      this.logger.error('Initial check failed', err.stack);
    });
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async handleCron() {
    this.logger.debug('Checking for pending notifications');
    await this.sendPendingNotifications();
  }

  private async sendPendingNotifications() {
    try {
      const pendingNotifications = await this.notificationService.getPendingNotifications();
      this.logger.log(`Found ${pendingNotifications.length} pending notifications`);

      for (const notification of pendingNotifications) {
        try {
          this.logger.log(`Processing notification: ${notification._id}`);
          const smsSent = await this.smsService.sendSms(notification);
          
          if (smsSent) {
            await this.notificationService.markAsSent(notification._id.toString());
            this.logger.log(`Successfully sent notification: ${notification._id}`);
          } else {
            this.logger.error(`Failed to send notification: ${notification._id}`);
          }
        } catch (error) {
          this.logger.error(
            `Error processing notification ${notification._id}: ${error.message}`,
            error.stack,
          );
        }
      }
    } catch (error) {
      this.logger.error(
        `Failed to fetch pending notifications: ${error.message}`,
        error.stack,
      );
    }
  }
}