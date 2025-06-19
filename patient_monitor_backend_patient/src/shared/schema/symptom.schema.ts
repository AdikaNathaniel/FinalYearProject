import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Symptom extends Document {
  @Prop({ required: true, index: true })
  patientId: string;

  @Prop({ required: true, index: true })
  username: string;

  @Prop({ required: true })
  feelingHeadache: string;

  @Prop({ required: true })
  feelingDizziness: string;

  @Prop({ required: true })
  vomitingAndNausea: string;

  @Prop({ required: true })
  painAtTopOfTommy: string;
}

export const SymptomSchema = SchemaFactory.createForClass(Symptom);