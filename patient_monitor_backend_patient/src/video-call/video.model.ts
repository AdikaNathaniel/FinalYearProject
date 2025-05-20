// src/models/chat-room.model.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class VideoRoom {
  @Prop({ required: true, unique: true })
  name: string;

  @Prop({ type: [{ type: String }], default: [] })
  participants: string[]; // Array of user IDs
}

export type VideoRoomDocument = VideoRoom & Document;
export const VideoRoomSchema = SchemaFactory.createForClass(VideoRoom);