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
    return this.messageModel.find().sort({ timestamp: 1 }).exec();
  }

  async getConversationMessages(userId1: string, userId2: string): Promise<Message[]> {
    const participants = [userId1, userId2].sort();
    const roomId = `room_${participants.join('_')}`;
    
    return this.messageModel
      .find({ roomId })
      .sort({ timestamp: 1 })
      .exec();
  }

  async markMessagesAsRead(messageIds: string[]): Promise<void> {
    await this.messageModel.updateMany(
      { _id: { $in: messageIds } },
      { $set: { isRead: true } }
    ).exec();
  }

  async getUnreadMessagesCount(userId: string): Promise<number> {
    return this.messageModel
      .countDocuments({ receiverId: userId, isRead: false })
      .exec();
  }

  async getUserConversations(userId: string): Promise<any[]> {
    return this.messageModel.aggregate([
      {
        $match: {
          $or: [{ senderId: userId }, { receiverId: userId }]
        }
      },
      {
        $sort: { timestamp: -1 }
      },
      {
        $group: {
          _id: "$roomId",
          lastMessage: { $first: "$$ROOT" },
          unreadCount: {
            $sum: {
              $cond: [{ $and: [{ $eq: ["$receiverId", userId] }, { $eq: ["$isRead", false] }] }, 1, 0]
            }
          }
        }
      },
      {
        $sort: { "lastMessage.timestamp": -1 }
      }
    ]).exec();
  }
}