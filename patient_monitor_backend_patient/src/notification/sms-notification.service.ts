// src/notification/sms-notification.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { Notification } from 'src/shared/schema/notification.schema';

@Injectable()
export class SmsNotificationService {
  private readonly logger = new Logger(SmsNotificationService.name);
  private readonly apiKey: string;
  private readonly senderId: string;
  private readonly defaultPhoneNumber: string;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = 'SXZtb3lhRldmZVVCSEdXUW1EVGU';
    this.senderId = 'Awo)Pa';
    this.defaultPhoneNumber = this.configService.get<string>(
      'DEFAULT_PHONE_NUMBER',
      '+233241744703',
    );
  }

  async sendSms(notification: Notification): Promise<boolean> {
    try {
      const response = await axios.post(
        'https://sms.arkesel.com/api/v2/sms/send',
        {
          sender: this.senderId,
          message: notification.message,
          recipients: [this.defaultPhoneNumber],
        },
        {
          headers: {
            'api-key': this.apiKey,
            'Content-Type': 'application/json',
          },
        },
      );

      this.logger.log(
        `SMS sent successfully to ${this.defaultPhoneNumber}: ${JSON.stringify(response.data)}`,
      );
      return true;
    } catch (error) {
      this.logger.error(
        `Failed to send SMS to ${this.defaultPhoneNumber}: ${error.message}`,
        error.stack,
      );
      return false;
    }
  }

  async sendScheduledSms(notification: Notification): Promise<boolean> {
    try {
      const scheduledDate = new Date(notification.scheduledAt);
      const formattedDate = scheduledDate.toLocaleString('en-GB', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      }).replace(',', '');

      const response = await axios.post(
        'https://sms.arkesel.com/api/v2/sms/send',
        {
          sender: this.senderId,
          message: notification.message,
          recipients: [this.defaultPhoneNumber],
          scheduled_date: formattedDate,
        },
        {
          headers: {
            'api-key': this.apiKey,
            'Content-Type': 'application/json',
          },
        },
      );

      this.logger.log(
        `Scheduled SMS set for ${formattedDate}: ${JSON.stringify(response.data)}`,
      );
      return true;
    } catch (error) {
      this.logger.error(
        `Failed to schedule SMS: ${error.message}`,
        error.stack,
      );
      return false;
    }
  }
}