import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Message extends Document {
  @Prop()
  role: string;

  @Prop()
  message: string;

  @Prop()
  time: string;
}

export const MessageSchema = SchemaFactory.createForClass(Message);
