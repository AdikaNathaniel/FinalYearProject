import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type PredictionHardwareDocument = PredictionHardware & Document;

@Schema({ timestamps: true })
export class PredictionHardware {
  @Prop({ required: true })
  preeclampsia_risk: string;

  @Prop({ required: true })
  anemia_risk: string;

  @Prop({ required: true })
  gdm_risk: string;

  // Auto-generated timestamps
  createdAt?: Date;
  updatedAt?: Date;
}

export const PredictionHardwareSchema = SchemaFactory.createForClass(PredictionHardware);