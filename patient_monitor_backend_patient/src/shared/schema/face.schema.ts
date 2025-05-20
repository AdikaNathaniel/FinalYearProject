import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Face extends Document {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true, type: Object })
  descriptor: any;

  @Prop()
  age?: number;

  @Prop()
  gender?: string;

  @Prop()
  genderProbability?: number;
}

export const FaceSchema = SchemaFactory.createForClass(Face);