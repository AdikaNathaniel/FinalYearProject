import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Room extends Document {
  @Prop({ required: true, unique: true })
  name: string;

  @Prop({ type: [String], default: [] })
  participants: string[];

  @Prop({ default: false })
  isActive: boolean;
}

export const RoomSchema = SchemaFactory.createForClass(Room);