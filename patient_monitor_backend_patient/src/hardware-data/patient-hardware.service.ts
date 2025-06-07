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
  async getLatestPatient(): Promise<PatientHardwareDocument | null> {
    return this.patientHardwareModel
      .findOne()
      .sort({ createdAt: -1 })
      .exec();
  }

  // Create prediction hardware record with auto timestamp and patient reference
  async createPrediction(createPredictionHardwareDto: CreatePredictionHardwareDto): Promise<{
    prediction: PredictionHardware;
    patient_name: string;
  }> {
    // Get the latest patient record
    const latestPatient = await this.getLatestPatient();
    
    if (!latestPatient) {
      throw new Error('No patient hardware records found to create prediction for');
    }

    // Create the prediction with patient reference
    const predictionData = {
      ...createPredictionHardwareDto,
      patient_id: latestPatient._id, // Add patient reference
    };

    const createdPrediction = new this.predictionHardwareModel(predictionData);
    const savedPrediction = await createdPrediction.save();

    return {
      prediction: savedPrediction,
      patient_name: latestPatient.patient_name || 'Unknown', // Assuming patient_name field exists
    };
  }

  // Get the latest prediction hardware record with patient name
  async getLatestPrediction(): Promise<{
    prediction: PredictionHardware;
    patient_name: string;
  } | null> {
    const latestPrediction = await this.predictionHardwareModel
      .findOne()
      .sort({ createdAt: -1 })
      .exec();

    if (!latestPrediction) {
      return null;
    }

    // If prediction has patient_id reference, get the patient data
    let patientName = 'Unknown';
    
    if (latestPrediction.patient_id) {
      const patient = await this.patientHardwareModel
        .findById(latestPrediction.patient_id)
        .exec();
      
      if (patient && patient.patient_name) {
        patientName = patient.patient_name;
      }
    } else {
      // If no patient_id reference, get the latest patient (fallback)
      const latestPatient = await this.getLatestPatient();
      if (latestPatient && latestPatient.patient_name) {
        patientName = latestPatient.patient_name;
      }
    }

    return {
      prediction: latestPrediction,
      patient_name: patientName,
    };
  }
}