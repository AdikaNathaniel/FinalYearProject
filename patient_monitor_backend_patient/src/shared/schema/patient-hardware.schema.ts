import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type PatientHardwareDocument = PatientHardware & Document;

@Schema({ timestamps: true })
export class PatientHardware {
  @Prop({ required: true, trim: true })
  patient_name: string;

  @Prop({ required: true, min: 1, max: 42 })
  gestational_week: number;

  @Prop({ required: true })
  temperature: number;

  @Prop({ required: true })
  systolic_bp: number;

  @Prop({ required: true })
  diastolic_bp: number;

  @Prop({ required: true })
  glucose: number;

  @Prop({ required: true, min: 0, max: 100 })
  spo2: number;

  @Prop({ required: true })
  heart_rate: number;

  @Prop({ required: true })
  bmi: number;

  createdAt?: Date;
  updatedAt?: Date;
}

export const PatientHardwareSchema = SchemaFactory.createForClass(PatientHardware);