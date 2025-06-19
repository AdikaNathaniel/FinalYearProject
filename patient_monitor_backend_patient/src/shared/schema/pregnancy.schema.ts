import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Pregnancy {
  @Prop({ required: true })
  patientId: string;

  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  patientName: string;

  @Prop({ required: true })
  startDate: Date;

  @Prop({ required: true, default: 0 })
  currentWeek: number;

  @Prop()
  nextAppointmentSchedule: Date;

  @Prop()
  lastUpdateSent: Date;
}

export type PregnancyDocument = Pregnancy & Document;
export const PregnancySchema = SchemaFactory.createForClass(Pregnancy);