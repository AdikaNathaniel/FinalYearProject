import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Prescription extends Document {
  @Prop({ required: true })
  patient_name: string;

  @Prop({ required: true })
  drug_name: string;

  @Prop({ required: true })
  dosage: string;

  @Prop({ required: true })
  route_of_administration: string;

  @Prop({ required: true })
  frequency: string;

  @Prop({ required: true })
  duration: string;

  @Prop({ required: true })
  start_date: string;

  @Prop({ required: true })
  end_date: string;

  @Prop({ required: true })
  quantity: number;

  @Prop()
  reason?: string;

  @Prop()
  notes?: string;
}

export const PrescriptionSchema = SchemaFactory.createForClass(Prescription);
