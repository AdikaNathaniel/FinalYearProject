import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export type OfflineReminderDocument = OfflineReminder & Document;

@Schema({ timestamps: true })
export class OfflineReminder {
  @Prop({ required: true })
  type: string;

  @Prop({ type: MongooseSchema.Types.Mixed, required: true })
  payload: any;

  @Prop({ default: false })
  synced: boolean;

  @Prop({ default: 0 })
  retryCount: number;

  @Prop()
  lastError?: string;

  @Prop({ default: Date.now })
  createdAt: Date;
}

export const OfflineReminderSchema = SchemaFactory.createForClass(OfflineReminder);