import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { 
  Appointment, 
  AppointmentDocument 
} from 'src/shared/schema/appointments.schema';
import { MessageService } from './sms-message.service';

@Injectable()
export class AppointmentsCronService {
  private readonly logger = new Logger(AppointmentsCronService.name);

  constructor(
    @InjectModel(Appointment.name)
    private readonly appointmentModel: Model<AppointmentDocument>,
    private readonly smsService: MessageService,
  ) {}

  /**
   * Send daily appointment summary at 9:00 AM every day
   */
  @Cron(CronExpression.EVERY_DAY_AT_9AM)
  async sendDailyAppointmentSummary() {
    this.logger.log('Running daily appointment summary cron job at 9 AM');
    
    try {
      // Get today's date range
      const today = new Date();
      const startOfDay = new Date(today);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(today);
      endOfDay.setHours(23, 59, 59, 999);

      // Find all confirmed appointments for today
      const confirmedAppointments = await this.appointmentModel.find({
        date: { $gte: startOfDay, $lte: endOfDay },
        status: 'confirmed',
      }).sort({ date: 1 }).exec();

      this.logger.debug(`Found ${confirmedAppointments.length} confirmed appointments for today`);

      // Format the appointments for SMS
      const message = this.smsService.formatAppointmentsForSms(confirmedAppointments);
      
      // Send the SMS with the summary
      await this.smsService.sendSms(message);
      
      this.logger.log('Daily appointment summary SMS sent successfully');
    } catch (error) {
      this.logger.error(`Error in daily appointment summary cron job: ${error.message}`);
    }
  }
}