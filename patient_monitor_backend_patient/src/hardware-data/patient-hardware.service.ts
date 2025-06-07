import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PatientHardware, PatientHardwareDocument } from 'src/shared/schema/patient-hardware.schema';
import { PredictionHardware, PredictionHardwareDocument } from 'src/shared/schema/prediction-hardware.schema';
import { CreatePatientHardwareDto } from 'src/users/dto/create-patient-hardware.dto';
import { CreatePredictionHardwareDto } from 'src/users/dto/create-prediction-hardware.dto';

@Injectable()
export class PatientHardwareService {
  constructor(
    @InjectModel(PatientHardware.name) private patientHardwareModel: Model<PatientHardwareDocument>,
    @InjectModel(PredictionHardware.name) private predictionHardwareModel: Model<PredictionHardwareDocument>
  ) {}

  // Create patient hardware record with auto timestamp
  async create(createPatientHardwareDto: CreatePatientHardwareDto): Promise<PatientHardware> {
    const createdPatient = new this.patientHardwareModel(createPatientHardwareDto);
    return createdPatient.save();
  }

  // Get the latest patient hardware record
  async getLatestPatient(): Promise<PatientHardware | null> {
    return this.patientHardwareModel
      .findOne()
      .sort({ createdAt: -1 })
      .exec();
  }

  // Create prediction hardware record with auto timestamp
  async createPrediction(createPredictionHardwareDto: CreatePredictionHardwareDto): Promise<PredictionHardware> {
    const createdPrediction = new this.predictionHardwareModel(createPredictionHardwareDto);
    return createdPrediction.save();
  }

  // Get the latest prediction hardware record
  async getLatestPrediction(): Promise<PredictionHardware | null> {
    return this.predictionHardwareModel
      .findOne()
      .sort({ createdAt: -1 })
      .exec();
  }
}