import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MedicsController } from './medics.controller';
import { MedicsService } from './medics.service';
import { Medic, MedicSchema } from 'src/shared/schema/medic.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Medic.name, schema: MedicSchema }]),
  ],
  controllers: [MedicsController],
  providers: [MedicsService],
})
export class MedicsModule {}