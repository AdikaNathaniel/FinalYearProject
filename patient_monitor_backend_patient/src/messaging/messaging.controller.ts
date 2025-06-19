import { Body, Controller, Post } from '@nestjs/common';
import { MessagingService } from './messaging.service';

@Controller('messaging')
export class MessagingController {
  constructor(private readonly messagingService: MessagingService) {}

  @Post('send')
  async sendNotification(@Body() body: { token: string; title: string; message: string }) {
    return this.messagingService.sendPushNotification(body.token, body.title, body.message);
  }

  @Post('appointment')
  async sendAppointmentNotification(@Body() body: { token: string; appointmentTime: string }) {
    const title = 'Appointment Reminder';
    const message = `Your appointment is scheduled for ${body.appointmentTime}.`;
    return this.messagingService.sendPushNotification(body.token, title, message);
  }
}