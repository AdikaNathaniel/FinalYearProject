// src/shared/schema/message.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Message extends Document {
  @Prop({ required: true })
  senderId: string;

  @Prop({ required: true })
  receiverId: string;

  @Prop({ required: true })
  content: string;

  @Prop({ required: true })
  roomId: string;

  @Prop({ default: Date.now })
  timestamp: Date;

  @Prop({ default: false })
  isRead: boolean;

  @Prop()
  messageType: string; // 'text', 'image', 'file'
}

export const MessageSchema = SchemaFactory.createForClass(Message);