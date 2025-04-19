import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Tracking extends Document {
  @Prop({ required: true })
  driverId: string;

  @Prop({ type: [Number], required: true })
  location: [number, number];

  @Prop({ required: true })
  lastUpdated: Date;
}

export const TrackingSchema = SchemaFactory.createForClass(Tracking);