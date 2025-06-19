import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type FaceAuthDocument = FaceAuth & Document;

@Schema({ timestamps: true })
export class FaceAuth {
  @Prop({ required: true, unique: true })
  userId: string;

  @Prop({ required: true })
  username: string;

  @Prop({ required: true, type: [Number] })
  faceDescriptor: number[];

  @Prop({ required: true, enum: ['admin', 'user'] })
  role: string;
}

export const FaceAuthSchema = SchemaFactory.createForClass(FaceAuth);