import { Module } from '@nestjs/common';
import { VideoGateway } from './video.gateway';
import { MongooseModule } from '@nestjs/mongoose';
import { Room, RoomSchema } from 'src/shared/schema/room.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Room.name, schema: RoomSchema }]),
  ],
  providers: [VideoGateway],
})
export class VideoModule {}