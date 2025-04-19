import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TrackingController } from 'src/tracking/tracking.controller';
import { TrackingService } from 'src/tracking/tracking.service';
import { Tracking, TrackingSchema } from 'src/shared/schema/tracking.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Tracking.name, schema: TrackingSchema }
    ])
  ],
  controllers: [TrackingController],
  providers: [TrackingService]
})
export class TrackingModule {}