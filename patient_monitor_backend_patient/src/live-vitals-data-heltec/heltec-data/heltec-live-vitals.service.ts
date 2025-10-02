
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { HeltecLiveVitals } from 'src/shared/schema/heltec-live-vitals.schema';
import { CreateHeltecLiveVitalsDto } from 'src/users/dto/create-heltec-live-vitals.dto';

@Injectable()
export class HeltecLiveVitalsService {
  constructor(@InjectModel(HeltecLiveVitals.name) private heltecVitalsModel: Model<HeltecLiveVitals>) {}

  // POST vitals
  async createVitals(dto: CreateHeltecLiveVitalsDto): Promise<HeltecLiveVitals> {
    const newVitals = new this.heltecVitalsModel(dto);
    return newVitals.save();
  }

  // GET latest vitals
  async getLatestVitals(): Promise<HeltecLiveVitals> {
    const vitals = await this.heltecVitalsModel.findOne().sort({ createdAt: -1 }).exec();
    if (!vitals) throw new NotFoundException('No vitals found');
    return vitals;
  }

  async updateLatestProteinLevel(proteinLevel: number) {
  const latest = await this.heltecVitalsModel.findOne().sort({ createdAt: -1 }).exec();
  if (!latest) throw new NotFoundException('No vitals found to update');

  latest.proteinLevel = proteinLevel;
  return latest.save();
}


  // GET all vitals history
  async getAllVitals(): Promise<HeltecLiveVitals[]> {
    return this.heltecVitalsModel.find().sort({ createdAt: -1 }).exec();
  }
}