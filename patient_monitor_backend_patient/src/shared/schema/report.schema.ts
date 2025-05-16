import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Report extends Document {
  @Prop({ required: true })
  body_temperature: number;

  @Prop({ required: true })
  heart_rate: number;

  @Prop({ required: true })
  oxygen_saturation: number;

  @Prop({ required: true })
  blood_pressure: string;

  @Prop({ required: true })
  blood_glucose: number;

  @Prop()
  notes?: string;

  @Prop()
  drugs?: string;
}

export const ReportSchema = SchemaFactory.createForClass(Report);
