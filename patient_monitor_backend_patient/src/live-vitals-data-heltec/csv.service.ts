import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CsvFile } from 'src/shared/schema/csv.schema';
import { CreateCsvDto } from 'src/users/dto/create-csv.dto';
import { createReadStream } from 'fs';
import { join } from 'path';

@Injectable()
export class CsvService {
  constructor(@InjectModel(CsvFile.name) private csvModel: Model<CsvFile>) {}

  async create(dto: CreateCsvDto): Promise<CsvFile> {
    const newFile = new this.csvModel(dto);
    return newFile.save();
  }

  async findOne(id: string): Promise<CsvFile> {
    const file = await this.csvModel.findById(id).exec();
    if (!file) throw new NotFoundException('CSV file not found');
    return file;
  }

  async getFileStream(id: string) {
    const file = await this.findOne(id);
    return createReadStream(join(process.cwd(), file.path));
  }

  async findLatestId(): Promise<string> {
  const latestFile = await this.csvModel
    .findOne()
    .sort({ _id: -1 }) 
    .exec();

  if (!latestFile) throw new NotFoundException('No CSV files found');

  return latestFile._id.toString(); // return as string
}

async findAllIds(): Promise<string[]> {
  const files = await this.csvModel.find().select('_id').exec();
  return files.map(file => file._id.toString());
}

}
