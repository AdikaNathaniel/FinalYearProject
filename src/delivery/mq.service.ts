import { Injectable } from '@nestjs/common';
import * as amqp from 'amqplib';

@Injectable()
export class MQService {
  private connection: amqp.Connection;
  private channel: amqp.Channel;

  async connect() {
    this.connection = await amqp.connect('amqp://localhost'); // Update if using a different broker
    this.channel = await this.connection.createChannel();
    await this.channel.assertQueue('delivery_updates');
  }

  async sendMessage(message: any) {
    if (!this.channel) {
      await this.connect();
    }
    this.channel.sendToQueue('delivery_updates', Buffer.from(JSON.stringify(message)));
  }
}
