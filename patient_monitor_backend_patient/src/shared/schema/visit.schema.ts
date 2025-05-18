import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Visit extends Document {
  @Prop({ required: true })
  patientName: string;

  @Prop({ required: true })
  visitDate: Date;

  @Prop({ default: false })
  reminderSent: boolean;

  @Prop({ default: 0 })
  dailyReminderCount: number;
}

export const VisitSchema = SchemaFactory.createForClass(Visit);