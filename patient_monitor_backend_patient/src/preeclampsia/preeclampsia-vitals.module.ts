import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PreeclampsiaVitalsController } from './preeclampsia-vitals.controller';
import { PreeclampsiaVitalsService } from './preeclampsia-vitals.service';
import { PreeclampsiaVitals, PreeclampsiaVitalsSchema } from 'src/shared/schema/preeclampsia-vitals.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PreeclampsiaVitals.name, schema: PreeclampsiaVitalsSchema }
    ]),
  ],
  controllers: [PreeclampsiaVitalsController],
  providers: [PreeclampsiaVitalsService],
})
export class PreeclampsiaVitalsModule {}