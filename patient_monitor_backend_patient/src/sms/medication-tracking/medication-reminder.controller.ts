import { Controller, Post, Body, Logger, HttpStatus, HttpException } from '@nestjs/common';
import { SmsService } from '../sms.service';
import { MedicationReminderDto } from 'src/users/dto/medication-reminder.dto';

@Controller('medication-reminders')
export class MedicationReminderController {
  private readonly logger = new Logger(MedicationReminderController.name);

  constructor(private readonly smsService: SmsService) {}

  @Post()
  async createMedicationReminder(@Body() dto: MedicationReminderDto) {
    try {
      const result = await this.smsService.createMedicationReminder(dto);
      return {
        status: 'success',
        message: 'Medication reminder created successfully',
        data: result,
      };
    } catch (error) {
      this.logger.error(`Failed to create medication reminder: ${error.message}`, error.stack);
      throw new HttpException(
        'Failed to create medication reminder',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post('send-pending')
  async sendPendingMedicationReminders() {
    try {
      const result = await this.smsService.processPendingMedicationReminders();
      return {
        status: 'success',
        message: 'Pending medication reminders processed',
        data: { sent: result.sent, failed: result.failed },
      };
    } catch (error) {
      this.logger.error(`Failed to process pending reminders: ${error.message}`, error.stack);
      throw new HttpException(
        'Failed to process pending reminders',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}