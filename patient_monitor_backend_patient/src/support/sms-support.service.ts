// src/support/support-sms.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { Support } from 'src/shared/schema/support.schema'; // Adjust path if needed

@Injectable()
export class SupportSmsService {
  private readonly logger = new Logger(SupportSmsService.name);
  private readonly apiKey: string;
  private readonly senderId: string;
  private readonly defaultPhoneNumber: string;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = 'R0lBd2RtanJrd3lsdmhjV1lrR2s'; // ⚠️ Move to env variable in production
    this.senderId = 'Awo)Pa';
    this.defaultPhoneNumber = this.configService.get<string>(
      'DEFAULT_PHONE_NUMBER',
      '+233241744703',
    );
  }

  async sendSupportSms(support: Support): Promise<boolean> {
    try {
     const message = `${support.name} (${support.phoneNumber}) sent a support request: "${support.message}"`;


      const response = await axios.post(
        'https://sms.arkesel.com/api/v2/sms/send',
        {
          sender: this.senderId,
          message,
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
        `Support SMS sent successfully to ${this.defaultPhoneNumber}: ${JSON.stringify(response.data)}`,
      );
      return true;
    } catch (error) {
      this.logger.error(
        `Failed to send support SMS to ${this.defaultPhoneNumber}: ${error.message}`,
        error.stack,
      );
      return false;
    }
  }
}
