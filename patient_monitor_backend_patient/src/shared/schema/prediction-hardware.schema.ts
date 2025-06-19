import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import * as mongoose from 'mongoose';

export type PredictionHardwareDocument = PredictionHardware & Document;

@Schema({ timestamps: true })
export class PredictionHardware {
  @Prop({ required: true })
  preeclampsia_risk: string;

  @Prop({ required: true })
  anemia_risk: string;

  @Prop({ required: true })
  gdm_risk: string;

@Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'PatientHardware' })
patient_id?: string;

  // Auto-generated timestamps
  createdAt?: Date;
  updatedAt?: Date;
}

export const PredictionHardwareSchema = SchemaFactory.createForClass(PredictionHardware);