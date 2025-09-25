// src/face-recognition/entities/face.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Face extends Document {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true, type: Object })
  descriptor: number[];  // Face descriptor for recognition

  @Prop()
  age?: number;

  @Prop()
  gender?: string;

  @Prop()
  imagePath?: string;
}

export const FaceSchema = SchemaFactory.createForClass(Face);