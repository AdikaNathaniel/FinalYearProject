import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MessageService {
  private readonly logger = new Logger(MessageService.name);
  private readonly smsApiKey: string;
  private readonly doctorPhoneNumber = '233241744703'; // Doctor's phone number

  constructor(private configService: ConfigService) {
    this.smsApiKey = 'QVZXZW9zVUdBREFZWlRIbVNqRUo';
    if (!this.smsApiKey) {
      this.logger.warn('ARKESLE_SMS_API_KEY not found in environment variables');
    }
  }

  async sendSms(message: string): Promise<boolean> {
    try {
      if (!this.smsApiKey) {
        this.logger.error('Cannot send SMS: Missing ARKESLE_SMS_API_KEY');
        return false;
      }

      // Arkesle SMS API endpoint
      const endpoint = 'https://sms.arkesel.com/api/v2/sms/send';
      
      // Prepare the request payload
      const payload = {
        apiKey: this.smsApiKey,
        to: this.doctorPhoneNumber,
        message: message,
        sender: 'Awo)Pa',
      };

      this.logger.debug(`Sending SMS to ${this.doctorPhoneNumber}`);
      
      // Send the request to Arkesle SMS API
      const response = await axios.post(endpoint, payload);
      
      if (response.status === 200 && response.data.success) {
        this.logger.log(`SMS sent successfully to ${this.doctorPhoneNumber}`);
        return true;
      } else {
        this.logger.error(`Failed to send SMS: ${JSON.stringify(response.data)}`);
        return false;
      }
    } catch (error) {
      this.logger.error(`Error sending SMS: ${error.message}`);
      return false;
    }
  }

  /**
   * Format appointments for SMS message
   */
  formatAppointmentsForSms(appointments: any[]): string {
    if (!appointments || appointments.length === 0) {
      return 'No appointments scheduled.';
    }

    const appointmentLines = appointments
      .map((apt, index) => {
        const date = new Date(apt.date);
        const timeStr = date.toLocaleTimeString('en-US', { 
          hour: '2-digit', 
          minute: '2-digit',
          hour12: true 
        });
        return `${index + 1}. ${timeStr} - ${apt.patientName} (${apt.status})`;
      })
      .join('\n');

    return `Daily Appointments Summary:\n${appointmentLines}`;
  }

  /**
   * Format appointment status change for SMS
   */
  formatStatusChangeSms(appointment: any): string {
    const date = new Date(appointment.date);
    const dateStr = date.toLocaleDateString();
    const timeStr = date.toLocaleTimeString('en-US', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: true 
    });
    
    return `Appointment Status Changed: ${appointment.patientName}'s appointment on ${dateStr} at ${timeStr} is now ${appointment.status.toUpperCase()}.`;
  }
}