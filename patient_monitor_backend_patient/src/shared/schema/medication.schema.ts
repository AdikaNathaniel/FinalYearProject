import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Medication {
  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  patientName: string;

  @Prop({ required: true })
  medicationName: string;

  @Prop({ required: true })
  dosage: string;

  @Prop({ required: true, enum: ['daily', 'weekly'] })
  frequency: string;

  @Prop({ required: true })
  time: string;

  @Prop()
  refillDate: Date;

  @Prop({
    type: {
      name: String,
      phone: String,
    },
  })
  pharmacy?: { name: string; phone: string };

  @Prop()
  lastReminderSent: Date;
}

export type MedicationDocument = Medication & Document;
export const MedicationSchema = SchemaFactory.createForClass(Medication);