import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Patient } from 'src/shared/schema/patient.schema';

@Injectable()
export class PatientService {
  constructor(
    @InjectModel(Patient.name) private patientModel: Model<Patient>,
  ) {}

  async create(patientData: Partial<Patient>): Promise<Patient> {
    // Ensure name is unique
    const existingPatient = await this.patientModel.findOne({ name: patientData.name }).exec();
    if (existingPatient) {
      throw new Error('Patient with this name already exists');
    }
    const createdPatient = new this.patientModel(patientData);
    return createdPatient.save();
  }

  async findByName(name: string): Promise<Patient> {
    return this.patientModel.findOne({ name }).exec();
  }

  async updateWeeksOfPregnancy(name: string, weeks: number): Promise<Patient> {
    return this.patientModel.findOneAndUpdate(
      { name },
      { weeksOfPregnancy: weeks },
      { new: true }
    ).exec();
  }
}