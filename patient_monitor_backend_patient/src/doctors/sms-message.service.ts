import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MessageService {
  private readonly logger = new Logger(MessageService.name);
  private readonly smsApiKey: string;
  private readonly doctorPhoneNumber = '233241744703'; // Doctor's phone number
  
  constructor(private configService: ConfigService) {
    // Get API key from environment variables via ConfigService
    this.smsApiKey = this.configService.get<string>('ARKESLE_SMS_API_KEY') || 'R0lBd2RtanJrd3lsdmhjV1lrR2s';
    
    if (!this.smsApiKey) {
      this.logger.warn('ARKESLE_SMS_API_KEY not found in environment variables');
    }
  }
  
  /**
   * Send SMS using Arkesel V2 API
   */
  async sendSms(message: string): Promise<boolean> {
    try {
      if (!this.smsApiKey) {
        this.logger.error('Cannot send SMS: Missing ARKESLE_SMS_API_KEY');
        return false;
      }
      
      // Arkesel SMS API V2 endpoint
      const endpoint = 'https://sms.arkesel.com/api/v2/sms/send';
      
      // Prepare the request payload according to API V2 format
      const payload = {
        sender: 'Awo)Pa', // Sender ID, max 11 chars without special characters or spaces
        message: message,
        recipients: [this.doctorPhoneNumber]
      };
      
      this.logger.debug(`Sending SMS to ${this.doctorPhoneNumber}`);
      
      // Set up request with API key in header as per V2 documentation
      const response = await axios.post(endpoint, payload, {
        headers: {
          'api-key': this.smsApiKey,
          'Content-Type': 'application/json'
        }
      });
      
      // Check for success response
      if (response.status === 200 && response.data.status === 'success') {
        this.logger.log(`SMS sent successfully to ${this.doctorPhoneNumber}`);
        return true;
      } else {
        this.logger.error(`Failed to send SMS: ${JSON.stringify(response.data)}`);
        return false;
      }
    } catch (error) {
      this.logger.error(`Error sending SMS: ${error.message}`);
      
      // Log more details about the error if available
      if (error.response) {
        this.logger.error(`API Error Response: ${JSON.stringify(error.response.data)}`);
      }
      
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
  
  /**
   * Alternative method to use Arkesel V1 API if needed
   */
  async sendSmsV1(message: string): Promise<boolean> {
    try {
      if (!this.smsApiKey) {
        this.logger.error('Cannot send SMS: Missing ARKESLE_SMS_API_KEY');
        return false;
      }
      
      // Arkesel SMS API V1 endpoint
      const endpoint = 'https://sms.arkesel.com/sms/api';
      
      // Prepare the request parameters according to V1 format
      const params = {
        action: 'send-sms',
        api_key: this.smsApiKey,
        to: this.doctorPhoneNumber,
        from: 'AwoPA',
        sms: message
      };
      
      this.logger.debug(`Sending SMS via V1 API to ${this.doctorPhoneNumber}`);
      
      // Send request with parameters in the URL query
      const response = await axios.get(endpoint, { params });
      
      // Check for success response
      if (response.data && response.data.code === 'ok') {
        this.logger.log(`SMS sent successfully via V1 API to ${this.doctorPhoneNumber}`);
        return true;
      } else {
        this.logger.error(`Failed to send SMS via V1 API: ${JSON.stringify(response.data)}`);
        return false;
      }
    } catch (error) {
      this.logger.error(`Error sending SMS via V1 API: ${error.message}`);
      return false;
    }
  }
}