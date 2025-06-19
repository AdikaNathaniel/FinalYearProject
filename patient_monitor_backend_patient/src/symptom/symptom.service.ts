import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Symptom } from 'src/shared/schema/symptom.schema';
import { CreateSymptomDto } from 'src/users/dto/create-symptom.dto';
import { SymptomDto } from 'src/users/dto/symptom.dto';

@Injectable()
export class SymptomsService {
  constructor(
    @InjectModel(Symptom.name) private readonly symptomModel: Model<Symptom>,
  ) {}

  async create(createSymptomDto: CreateSymptomDto): Promise<SymptomDto> {
    const createdSymptom = new this.symptomModel(createSymptomDto);
    const symptom = await createdSymptom.save();
    return this.mapToDto(symptom);
  }

  async findAll(): Promise<SymptomDto[]> {
    const symptoms = await this.symptomModel.find().exec();
    return symptoms.map(this.mapToDto);
  }

  async findByUsername(username: string): Promise<SymptomDto[]> {
    const symptoms = await this.symptomModel
      .find({ username: username })
      .sort({ createdAt: -1 }) 
      .exec();
    return symptoms.map(this.mapToDto);
  }

  private mapToDto(symptom: any): SymptomDto {
    return {
      id: symptom._id,
      username: symptom.username,
      feelingHeadache: symptom.feelingHeadache,
      feelingDizziness: symptom.feelingDizziness,
      vomitingAndNausea: symptom.vomitingAndNausea,
      painAtTopOfTommy: symptom.painAtTopOfTommy,
      createdAt: symptom.createdAt,
      updatedAt: symptom.updatedAt,
    };
  }
}