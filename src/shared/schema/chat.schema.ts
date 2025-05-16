import { Schema, Document } from 'mongoose';
import { Prop, SchemaFactory, Schema as SchemaDecorator } from '@nestjs/mongoose';
import { IsString, IsNotEmpty, IsISO8601 } from 'class-validator';

@SchemaDecorator({ timestamps: true })
export class Chat extends Document {
  @IsString()
  @IsNotEmpty()
  @Prop({ required: true })
  message: string;

  @IsString()
  @IsNotEmpty()
  @Prop({ required: true })
  receiverEmail: string;

  @IsISO8601()
  @Prop({ required: true, default: () => new Date().toISOString() })
  timestamps: string;
}

export const ChatSchema = SchemaFactory.createForClass(Chat);