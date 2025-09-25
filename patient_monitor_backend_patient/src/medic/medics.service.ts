import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Medic } from 'src/shared/schema/medic.schema';
import { CreateMedicDto } from 'src/users/dto/create-medic.dto';
import { UpdateMedicDto } from 'src/users/dto/update-medic.dto';
import { existsSync, unlinkSync } from 'fs';
import { join } from 'path';

@Injectable()
export class MedicsService {
  constructor(@InjectModel(Medic.name) private medicModel: Model<Medic>) {}

  async create(createMedicDto: CreateMedicDto): Promise<Medic> {
    const createdMedic = new this.medicModel(createMedicDto);
    return createdMedic.save();
  }

  async findAll(): Promise<Medic[]> {
    return this.medicModel.find().lean().exec();
  }

  async findOne(fullName: string): Promise<Medic> {
    return this.medicModel.findOne({ fullName }).lean().exec();
  }

   async findById(id: string): Promise<Medic | null> {
    // Replace with your actual ORM/database logic
    return await this.medicModel.findById(id).exec();
  }

  async update(
    fullName: string,
    updateMedicDto: UpdateMedicDto,
  ): Promise<Medic> {
    const existingMedic = await this.medicModel.findOne({ fullName }).exec();
    
    // If there's a new profile photo and an existing one, delete the old one
    if (existingMedic && existingMedic.profilePhoto && updateMedicDto.profilePhoto 
        && existingMedic.profilePhoto !== updateMedicDto.profilePhoto) {
      try {
        const oldFilePath = join(process.cwd(), 'uploads', existingMedic.profilePhoto);
        if (existsSync(oldFilePath)) {
          unlinkSync(oldFilePath);
        }
      } catch (err) {
        console.error('Error deleting old profile photo:', err);
      }
    }

    const updatedMedic = await this.medicModel
      .findOneAndUpdate({ fullName }, updateMedicDto, { 
        new: true,  // Return the updated document
        runValidators: true  // Run schema validators
      })
      .lean()
      .exec();
      
    return updatedMedic;
  }


   async findSimilar(query: string): Promise<Medic[]> {
    // Example implementation: search by fullName using regex (case-insensitive)
    return this.medicModel.find({
      fullName: { $regex: query, $options: 'i' }
    }).exec();
  }

 

  async remove(fullName: string): Promise<Medic> {
  const medic = await this.medicModel.findOneAndDelete({ fullName }).exec();
  
  if (!medic) {
    return null;
  }
  
  if (medic.profilePhoto) {
    try {
      const filePath = join(process.cwd(), 'uploads', medic.profilePhoto);
      if (existsSync(filePath)) {
        unlinkSync(filePath);
      }
    } catch (err) {
      console.error('Error deleting profile photo:', err);
    }
  }
  
  return medic;
}

async removeById(id: string): Promise<Medic> {
  const medic = await this.medicModel.findByIdAndDelete(id).exec();
  
  if (!medic) {
    return null;
  }
  
  if (medic.profilePhoto) {
    try {
      const filePath = join(process.cwd(), 'uploads', medic.profilePhoto);
      if (existsSync(filePath)) {
        unlinkSync(filePath);
      }
    } catch (err) {
      console.error('Error deleting profile photo:', err);
    }
  }
  
  return medic;
}
}