import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type HealthDataDocument = HealthData & Document;

@Schema({ timestamps: true })
export class HealthData {
  @Prop({ required: true })
  patient_name: string;

  @Prop({ required: true })
  gestational_week: number;

  @Prop({ required: true })
  temperature: number;

  @Prop({ required: true })
  systolic_bp: number;

  @Prop({ required: true })
  diastolic_bp: number;

  @Prop({ required: true })
  glucose: number;

  @Prop({ required: true })
  spo2: number;

  @Prop({ required: true })
  heart_rate: number;

  @Prop({ required: true })
  bmi: number;

  @Prop({ required: true })
  preeclampsia_risk: boolean;

  @Prop({ required: true })
  anemia_risk: boolean;

  @Prop({ required: true })
  gdm_risk: boolean;

  @Prop({ default: Date.now })
  received_at: Date;
}

export const HealthDataSchema = SchemaFactory.createForClass(HealthData);