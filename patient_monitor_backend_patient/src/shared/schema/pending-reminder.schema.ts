import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export type PendingReminderDocument = PendingReminder & Document;

@Schema({ timestamps: true })
export class PendingReminder {
  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  message: string;

  @Prop({ required: true })
  type: string;

  @Prop()
  referenceId?: string;

  @Prop({ default: 0 })
  retryCount: number;

  @Prop()
  lastError?: string;

  @Prop({ default: Date.now })
  createdAt: Date;
}

export const PendingReminderSchema = SchemaFactory.createForClass(PendingReminder);