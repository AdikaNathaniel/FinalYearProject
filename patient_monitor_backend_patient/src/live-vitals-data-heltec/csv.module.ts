import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CsvController } from './csv.controller';
import { CsvService } from './csv.service';
import { CsvFile, CsvFileSchema } from 'src/shared/schema/csv.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: CsvFile.name, schema: CsvFileSchema }]),
  ],
  controllers: [CsvController],
  providers: [CsvService],
})
export class CsvModule {}
