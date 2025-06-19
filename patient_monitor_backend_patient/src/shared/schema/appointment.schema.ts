import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Appointment extends Document {
  @Prop({ required: true })
  email: string;

  @Prop({ required: true })
  day: string;

  @Prop({ required: true })
  time: string;

  @Prop({ required: true, type: Object }) // Ensure this is defined as required
  details: {
    patient_name: string;
    condition: string;
    notes?: string;
  };
}

export const AppointmentSchema = SchemaFactory.createForClass(Appointment);