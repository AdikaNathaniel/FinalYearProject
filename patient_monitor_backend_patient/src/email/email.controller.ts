import { Controller } from '@nestjs/common';
import { MessagePattern } from '@nestjs/microservices';
import { EmailService } from './email.service';

@Controller()
export class EmailController {
  constructor(private readonly emailService: EmailService) {}

  @MessagePattern('send_otp_email')
  async handleSendOTPEmail(data: { email: string; otp: string }) {
    return await this.emailService.sendOTPEmail(data.email, data.otp);
  }
}