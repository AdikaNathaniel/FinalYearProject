// src/schemas/chart-data.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class ChartData extends Document {
  @Prop({ required: true })
  glucose: number;

  @Prop({ required: true })
  systolicBP: number;

  @Prop({ required: true })
  diastolicBP: number;

  @Prop({ required: true })
  heartRate: number;

  @Prop({ required: true })
  spo2: number;

  @Prop({ required: true })
  skinTemp: number;

  @Prop({ required: true })
  bodyTemp: number;

  @Prop({ required: true })
  accelX: number;

  @Prop({ required: true })
  accelY: number;

  @Prop({ required: true })
  accelZ: number;

  @Prop({ required: true })
  gyroX: number;

  @Prop({ required: true })
  gyroY: number;

  @Prop({ required: true })
  gyroZ: number;

  @Prop({ default: 0 })
  proteinLevel: number;

   @Prop({ required: false, default: Date.now })
   createdAt: Date;

 @Prop({ required: false, default: Date.now })
  updatedAt: Date;
}

export const ChartDataSchema = SchemaFactory.createForClass(ChartData);
