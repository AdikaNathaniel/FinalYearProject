import { Injectable } from '@nestjs/common';
import { ClientProxy, ClientProxyFactory, Transport } from '@nestjs/microservices';

@Injectable()
export class NotificationService {
  private emailClient: ClientProxy;

  constructor() {
    this.emailClient = ClientProxyFactory.create({
      transport: Transport.RMQ,
      options: {
        urls: [process.env.RABBITMQ_URL || 'amqp://localhost:5672'],
        queue: 'email_queue',
        queueOptions: {
          durable: true,
        },
      },
    });
  }

  async sendOTPNotification(email: string, otp: string) {
    try {
      return await this.emailClient
        .send('send_otp_email', { email, otp })
        .toPromise();
    } catch (error) {
      return { success: false, message: error.message };
    }
  }
}