import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class SmsRecord extends Document {
  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  message: string;

  @Prop({ enum: ['pending', 'sent', 'failed'], default: 'pending' })
  status: string;

  @Prop()
  sentAt: Date;

  @Prop()
  error: string;
}

export const SmsRecordSchema = SchemaFactory.createForClass(SmsRecord);