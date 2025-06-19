import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class SmsRecord {
  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  message: string;

  @Prop()
  failureReason?: string;

  @Prop({
    required: true,
    enum: ['appointment', 'nutrition', 'medication', 'pregnancy', 'OUTBOUND', 'INBOUND'],
    default: 'OUTBOUND'
  })
  type: string;

  @Prop({ required: true, enum: ['pending', 'sent', 'failed'], default: 'pending' })
  status: string;

  @Prop()
  sentAt: Date;
}

export type SmsRecordDocument = SmsRecord & Document;
export const SmsRecordSchema = SchemaFactory.createForClass(SmsRecord);