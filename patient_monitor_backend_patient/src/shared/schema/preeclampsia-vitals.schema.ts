import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class PreeclampsiaVitals extends Document {
  @Prop()
  patientId: string;

  @Prop()
  systolicBP: number;

  @Prop()
  diastolicBP: number;

  @Prop()
  proteinUrine: number;

  @Prop()
  map: number;

  @Prop()
  status: string;

  @Prop()
  createdAt?: Date;

  @Prop()
  updatedAt?: Date;
}

export const PreeclampsiaVitalsSchema = SchemaFactory.createForClass(PreeclampsiaVitals);