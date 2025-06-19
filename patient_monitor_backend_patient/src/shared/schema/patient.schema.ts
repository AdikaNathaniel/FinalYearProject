import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Patient extends Document {
  @Prop({ required: true, unique: true })
  name: string;

  @Prop({ required: true, min: 1, max: 42 })
  weeksOfPregnancy: number;

  @Prop({ required: true })
  phoneNumber: string;

  @Prop({ default: Date.now })
  createdAt: Date;
}

export const PatientSchema = SchemaFactory.createForClass(Patient);