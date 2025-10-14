import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class HeltecLiveVitals extends Document {
  @Prop() glucose: number;
  @Prop() systolicBP: number;
  @Prop() diastolicBP: number;
  @Prop() heartRate: number;
  @Prop() spo2: number;
  @Prop() skinTemp: number;
  @Prop() bodyTemp: number;
  @Prop() accelX: number;
  @Prop() accelY: number;
  @Prop() accelZ: number;
  @Prop() gyroX: number;
  @Prop() gyroY: number;
  @Prop() gyroZ: number;

  @Prop()
  createdAt?: Date;
  
  // Optional field
  @Prop({ required: false }) proteinLevel?: number;
}

export const HeltecLiveVitalsSchema = SchemaFactory.createForClass(HeltecLiveVitals);
