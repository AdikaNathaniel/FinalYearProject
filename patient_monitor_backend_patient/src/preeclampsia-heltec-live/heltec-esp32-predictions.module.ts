import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HeltecEsp32PredictionsService } from './heltec-esp32-predictions.service';
import { HeltecEsp32PredictionsController } from './heltec-esp32-predictions.controller';
import { PreeclampsiaVitals, PreeclampsiaVitalsSchema } from 'src/shared/schema/preeclampsia-vitals.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PreeclampsiaVitals.name, schema: PreeclampsiaVitalsSchema }
    ])
  ],
  controllers: [HeltecEsp32PredictionsController],
  providers: [HeltecEsp32PredictionsService],
  exports: [HeltecEsp32PredictionsService]
})
export class HeltecEsp32PredictionsModule {}