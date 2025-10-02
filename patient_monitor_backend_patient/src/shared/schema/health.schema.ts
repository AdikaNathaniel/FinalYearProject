import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type HealthDocument = Health & Document;

@Schema()
export class Health {
  @Prop({ required: true })
  parity: number;

  @Prop({ required: true })
  gravida: number;

  @Prop({ required: true })
  gestationalAge: number;

  @Prop({ required: true })
  age: number;

  @Prop({ required: false })
  hasDiabetes: string;

  @Prop({ required: false })
  hasAnemia: string;

  @Prop({ required: false })
  hasPreeclampsia: string;

  @Prop({ required: false })
  hasGestationalDiabetes: string;

  @Prop({ required: false })
  name: string;

  @Prop({
    default: () => new Date().toUTCString().split(' GMT')[0] + ' GMT',
  })
  createdAt: string;
}

export const HealthSchema = SchemaFactory.createForClass(Health);
