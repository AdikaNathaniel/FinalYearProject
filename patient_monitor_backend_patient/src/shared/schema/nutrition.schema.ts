import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class NutritionProfile {
  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  patientName: string;

  @Prop({ required: true, type: Number })
  trimester: number;

  @Prop({ default: 8 })
  waterIntakeGoal: number;

  @Prop({ type: [String], default: [] })
  deficiencies: string[];

  @Prop()
  lastWaterReminderSent: Date;

  @Prop()
  lastNutritionTipSent: Date;
}

export type NutritionProfileDocument = NutritionProfile & Document;
export const NutritionProfileSchema = SchemaFactory.createForClass(NutritionProfile);