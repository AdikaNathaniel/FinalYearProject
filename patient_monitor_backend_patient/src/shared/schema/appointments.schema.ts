import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Appointment {
  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  patientName: string;

  @Prop({ required: true })
  date: Date;

  @Prop({ required: true })
  doctor: string;

  @Prop({ required: true })
  location: string;

  @Prop({ required: true })
  purpose: string;

  @Prop()
  specialInstructions?: string;

  @Prop({ default: false })
  confirmed: boolean;

  @Prop({
    type: {
      weekBefore: { type: Boolean, default: false },
      twoDaysBefore: { type: Boolean, default: false },
      dayBefore: { type: Boolean, default: false },
    },
    default: {},
  })
  reminders: {
    weekBefore: boolean;
    twoDaysBefore: boolean;
    dayBefore: boolean;
  };
}

export type AppointmentDocument = Appointment & Document;
export const AppointmentSchema = SchemaFactory.createForClass(Appointment);