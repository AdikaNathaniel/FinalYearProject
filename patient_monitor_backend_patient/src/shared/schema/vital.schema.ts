import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({
  collection: 'vitals',
  timestamps: true,
  toJSON: {
    virtuals: true,
    versionKey: false,
    transform: (doc, ret) => {
      ret.id = ret._id;
      delete ret._id;
    }
  }
})
export class Vital extends Document {
  @Prop({ required: true, index: true })
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
   glucose: number;

  @Prop({ required: true })
  severity: string;

  @Prop({ required: true })
  rationale: string;

  @Prop({ type: String })
  mlSeverity?: string;

  @Prop({ type: Object })
  mlProbability?: Record<string, number>;

  @Prop({ default: Date.now })
  createdAt: Date;
}

export const VitalSchema = SchemaFactory.createForClass(Vital);