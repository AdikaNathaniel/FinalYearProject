import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Contact extends Document {
  @Prop({ required: false })
  userId: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  phoneNumber: string;

  @Prop()
  email?: string;

  @Prop()
  relationship?: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const ContactSchema = SchemaFactory.createForClass(Contact);