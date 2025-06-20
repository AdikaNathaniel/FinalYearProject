import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Vital extends Document {
  @Prop({ required: true })
  patientId: string;

  @Prop({ required: true })
  systolic: number;

  @Prop({ required: true })
  diastolic: number;

  @Prop({ required: true })
  map: number;

  @Prop({ required: true })
  proteinuria: number;

  @Prop({ required: true })
  temperature: number;

  @Prop({ required: true })
  heartRate: number;

  @Prop({ required: true })
  spo2: number;

  @Prop({ required: true })
  severity: string;

  @Prop()
  rationale?: string;

  // ✅ Explicitly define createdAt for access in TypeScript
  readonly createdAt: Date;
}

export const VitalSchema = SchemaFactory.createForClass(Vital);
