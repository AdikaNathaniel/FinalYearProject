import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Medic } from 'src/shared/schema/medic.schema';
import { CreateMedicDto } from 'src/users/dto/create-medic.dto';
import { UpdateMedicDto } from 'src/users/dto/update-medic.dto';
import { unlinkSync } from 'fs';
import { join } from 'path';

@Injectable()
export class MedicsService {
  constructor(@InjectModel(Medic.name) private medicModel: Model<Medic>) {}

  async create(createMedicDto: CreateMedicDto): Promise<Medic> {
    const createdMedic = new this.medicModel(createMedicDto);
    return createdMedic.save();
  }

  async findAll(): Promise<Medic[]> {
    return this.medicModel.find().exec();
  }

  async findOne(fullName: string): Promise<Medic> {
    return this.medicModel.findOne({ fullName }).exec();
  }

  async update(
    fullName: string,
    updateMedicDto: UpdateMedicDto,
  ): Promise<Medic> {
    return this.medicModel
      .findOneAndUpdate({ fullName }, updateMedicDto, { new: true })
      .exec();
  }

  async remove(fullName: string): Promise<Medic> {
    const medic = await this.medicModel.findOneAndDelete({ fullName }).exec();
    if (medic && medic.profilePhoto) {
      try {
        const filePath = join(process.cwd(), 'uploads', medic.profilePhoto);
        unlinkSync(filePath);
      } catch (err) {
        console.error('Error deleting profile photo:', err);
      }
    }
    return medic;
  }
}