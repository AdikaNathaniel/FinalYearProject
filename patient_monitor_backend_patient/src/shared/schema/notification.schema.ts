// src/notification/schemas/notification.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum NotificationRole {
  ADMIN = 'Admin',
  DOCTOR = 'Doctor',
}

@Schema({ timestamps: true })
export class Notification extends Document {
  @Prop({
    type: String,
    enum: NotificationRole,
    required: true,
  })
  role: NotificationRole;

  @Prop({ required: true })
  message: string;

  @Prop({ required: true })
  scheduledAt: Date;

  @Prop({ default: false })
  isSent: boolean;

  @Prop()
  sentAt?: Date;

  @Prop({ default: false })
  isRead: boolean;

  @Prop()
  readAt?: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);