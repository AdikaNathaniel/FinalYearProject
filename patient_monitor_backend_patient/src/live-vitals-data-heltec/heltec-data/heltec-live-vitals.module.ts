import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HeltecLiveVitalsController } from './heltec-live-vitals.controller';
import { HeltecLiveVitalsService } from './heltec-live-vitals.service';
import { HeltecLiveVitals, HeltecLiveVitalsSchema } from 'src/shared/schema/heltec-live-vitals.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: HeltecLiveVitals.name, schema: HeltecLiveVitalsSchema }]),
  ],
  controllers: [HeltecLiveVitalsController],
  providers: [HeltecLiveVitalsService],
})
export class HeltecLiveVitalsModule {}
