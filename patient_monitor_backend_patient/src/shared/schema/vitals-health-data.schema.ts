import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export enum InputMethod {
  MANUAL = 'manual',
  WEARABLE = 'wearable',
}

@Schema({ timestamps: true })
export class VitalsHealthData extends Document {
//   @Prop({ required: true, type: MongooseSchema.Types.ObjectId, ref: 'User' })
//   userId: string;
  @Prop({ required: true, type: String })
  userId: string;


  @Prop({
    required: true,
    enum: InputMethod,
    default: InputMethod.MANUAL,
  })
  inputMethod: InputMethod;

  @Prop({
    type: {
      systolic: { type: Number, min: 60, max: 250 },
      diastolic: { type: Number, min: 40, max: 150 },
    },
    required: true,
  })
  bloodPressure: {
    systolic: number;
    diastolic: number;
  };

  @Prop({ type: Number, min: 30, max: 300 })
  heartRate: number;

  @Prop({ type: Number, min: 70, max: 100 })
  spO2: number;

  @Prop({ type: Number, min: 50, max: 400 })
  bloodGlucose: number;

  @Prop({ type: Number, min: 0, max: 1000 })
  proteinInUrine: number;

  @Prop({ required: true, default: () => new Date() })
  timestamp: Date;

  @Prop()
  wearableDeviceId: string;
}

export const VitalsHealthDataSchema = SchemaFactory.createForClass(VitalsHealthData);

// Index for efficient querying
VitalsHealthDataSchema.index({ userId: 1, timestamp: -1 });
