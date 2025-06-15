import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { SmsRecord } from 'src/shared/schema/sms-record.schema';

@Injectable()
export class AntenatalVisitSmsService {
  private readonly logger = new Logger(AntenatalVisitSmsService.name);
  private readonly smsApiUrl = 'https://sms.arkesel.com/api/v2/sms/send';
  private readonly senderId = 'Awo)Pa';

  constructor(
    private readonly configService: ConfigService,
    private readonly httpService: HttpService,
    @InjectModel(SmsRecord.name) private readonly smsRecordModel: Model<SmsRecord>,
  ) {}

  private formatPhoneNumber(phone: string): string {
    if (phone.startsWith('0')) {
      return `+233${phone.substring(1)}`;
    }
    if (!phone.startsWith('+')) {
      return `+${phone}`;
    }
    return phone;
  }

  private async createSmsRecord(phone: string, message: string) {
    return this.smsRecordModel.create({
      phone,
      message,
      status: 'pending',
      createdAt: new Date(),
    });
  }

  private async handleSmsError(error: any, smsRecord: any, phone: string, message: string) {
    this.logger.error(`Failed to send SMS to ${phone}: ${error.message}`);
    smsRecord.status = 'failed';
    smsRecord.error = error.message;
    await smsRecord.save();
  }

  async sendVisitScheduleSms(phone: string, patientName: string, visitDates: Date[]): Promise<boolean> {
    const formattedPhone = this.formatPhoneNumber(phone);
    const formattedDates = visitDates.map(date => new Date(date).toLocaleDateString()).join(', ');
    
    const message = `Dear ${patientName}, your antenatal visits have been scheduled for: ${formattedDates}. ` +
                  `Please arrive on time for each appointment. Thank you.`;
    
    const smsRecord = await this.createSmsRecord(formattedPhone, message);

    try {
      const apiKey = 'R0lBd2RtanJrd3lsdmhjV1lrR2s';
      if (!apiKey) {
        throw new Error('ARKESEL_API_KEY environment variable is not set');
      }

      this.logger.log(`Sending visit schedule SMS to ${formattedPhone}`);

      const response = await firstValueFrom(
        this.httpService.post(
          this.smsApiUrl,
          {
            sender: this.senderId,
            message,
            recipients: [formattedPhone],
          },
          {
            headers: { 'api-key': apiKey },
            timeout: 10000,
          },
        ),
      );

      if (response.data.status === 'success') {
        smsRecord.status = 'sent';
        smsRecord.sentAt = new Date();
        await smsRecord.save();
        return true;
      } else {
        throw new Error(`SMS API returned non-success status: ${JSON.stringify(response.data)}`);
      }
    } catch (error) {
      await this.handleSmsError(error, smsRecord, formattedPhone, message);
      return false;
    }
  }



  async sendSms(phone: string, message: string): Promise<boolean> {
  const formattedPhone = this.formatPhoneNumber(phone);
  const smsRecord = await this.createSmsRecord(formattedPhone, message);

  try {
    const apiKey = 'R0lBd2RtanJrd3lsdmhjV1lrR2s';
    if (!apiKey) {
      throw new Error('ARKESEL_API_KEY environment variable is not set');
    }

    this.logger.log(`Sending SMS to ${formattedPhone}`);

    const response = await firstValueFrom(
      this.httpService.post(
        this.smsApiUrl,
        {
          sender: this.senderId,
          message,
          recipients: [formattedPhone],
        },
        {
          headers: { 'api-key': apiKey },
          timeout: 10000,
        },
      ),
    );

    if (response.data.status === 'success') {
      smsRecord.status = 'sent';
      smsRecord.sentAt = new Date();
      await smsRecord.save();
      return true;
    } else {
      throw new Error(`SMS API returned non-success status: ${JSON.stringify(response.data)}`);
    }
  } catch (error) {
    await this.handleSmsError(error, smsRecord, formattedPhone, message);
    return false;
  }
}
}