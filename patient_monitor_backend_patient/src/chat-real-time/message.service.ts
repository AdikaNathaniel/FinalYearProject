// src/message/message.service.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Message } from 'src/shared/schema/message.schema';
import { Model } from 'mongoose';

@Injectable()
export class MessageService {
  constructor(@InjectModel(Message.name) private messageModel: Model<Message>) {}

  async saveMessage(messageData: any): Promise<Message> {
    const createdMessage = new this.messageModel(messageData);
    return createdMessage.save();
  }

  async getAllMessages(): Promise<Message[]> {
    return this.messageModel.find().sort({ createdAt: -1 }).exec();
  }
}
