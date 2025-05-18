import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { Patient } from  './patient.schema'; 


@Schema()
export class Visit extends Document {
  @Prop({ type: String, ref: 'Patient', required: true })
  patientName: string;

  @Prop({ required: true })
  visitDate: Date;

  @Prop({ default: false })
  completed: boolean;

  @Prop({ default: false })
  reminderSent: boolean;
}

export const VisitSchema = SchemaFactory.createForClass(Visit);