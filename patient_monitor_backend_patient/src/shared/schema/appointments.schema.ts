// src/shared/schema/appointments.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export type AppointmentDocument = Appointment & Document;

export type AppointmentStatus = 'pending' | 'confirmed' | 'canceled';

@Schema({ timestamps: true })
export class Appointment {
  @Prop({ required: true })
  patientName: string;

  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  doctor: string;
  
  // @Prop({ type: String, required: true })
  // doctorName: string;

  @Prop({ required: true })
  date: Date;

  @Prop()
  purpose: string;

  @Prop()
  location: string;

  @Prop({ type: String, enum: ['pending', 'confirmed', 'canceled'], default: 'pending' })
  status: AppointmentStatus;

  @Prop({ type: Boolean })
  confirmed?: boolean;

  @Prop({ type: Date })
  confirmedAt?: Date;

  @Prop({
    type: {
      weekBefore: { type: Boolean, default: true },
      twoDaysBefore: { type: Boolean, default: true },
      dayBefore: { type: Boolean, default: true },
    },
  })
  reminders: {
    weekBefore: boolean;
    twoDaysBefore: boolean;
    dayBefore: boolean;
  };
}

export const AppointmentSchema = SchemaFactory.createForClass(Appointment);