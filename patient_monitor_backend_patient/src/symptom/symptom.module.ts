import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SymptomsController } from './symptom.controller';
import { SymptomsService } from './symptom.service';
import { Symptom, SymptomSchema } from 'src/shared/schema/symptom.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Symptom.name, schema: SymptomSchema }]),
  ],
  controllers: [SymptomsController],
  providers: [SymptomsService],
})
export class SymptomsModule {}