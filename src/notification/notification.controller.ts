import { Controller, Post, Body } from '@nestjs/common';
import { NotificationService } from './notification.service';

@Controller('notifications')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post('send-otp')
  async sendOTP(@Body() data: { email: string; otp: string }) {
    return await this.notificationService.sendOTPNotification(
      data.email,
      data.otp,
    );
  }
}