import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PreeclampsiaVitals } from 'src/shared/schema/preeclampsia-vitals.schema';
import { CreatePreeclampsiaVitalsDto } from 'src/users/dto/create-preeclampsia-vitals.dto';
import { UpdatePreeclampsiaVitalsDto } from 'src/users/dto/update-preeclampsia-vitals.dto';
import { PreeclampsiaVitalsResponseDto } from 'src/users/dto/preeclampsia-vitals-response.dto';

@Injectable()
export class HeltecEsp32PredictionsService {
  constructor(
    @InjectModel(PreeclampsiaVitals.name) 
    private preeclampsiaVitalsModel: Model<PreeclampsiaVitals>
  ) {}

  private calculateMAP(systolicBP: number, diastolicBP: number): number {
    return Math.round((systolicBP + 2 * diastolicBP) / 3 * 100) / 100;
  }

  private determineStatus(map: number, proteinUrine: number): string {
    if (proteinUrine < 2) {
      return 'no_preeclampsia';
    } else if (map >= 130) {
      return 'severe_preeclampsia';
    } else if (map >= 125 && map <= 129) {
      return 'moderate_preeclampsia';
    } else if (map >= 114 && map <= 124) {
      return 'mild_preeclampsia';
    } else {
      return 'no_preeclampsia';
    }
  }

  async createPrediction(
    createPreeclampsiaVitalsDto: CreatePreeclampsiaVitalsDto
  ): Promise<PreeclampsiaVitalsResponseDto> {
    const map = this.calculateMAP(
      createPreeclampsiaVitalsDto.systolicBP,
      createPreeclampsiaVitalsDto.diastolicBP,
    );
    const status = this.determineStatus(map, createPreeclampsiaVitalsDto.proteinUrine);

    const createdPrediction = new this.preeclampsiaVitalsModel({
      ...createPreeclampsiaVitalsDto,
      map,
      status,
    });

    const savedPrediction = await createdPrediction.save();
    return this.mapToResponseDto(savedPrediction);
  }

  async getAllPredictions(): Promise<PreeclampsiaVitalsResponseDto[]> {
    const predictions = await this.preeclampsiaVitalsModel
      .find()
      .sort({ createdAt: -1 })
      .exec();
    return predictions.map(this.mapToResponseDto);
  }

  async getPredictionsByPatientId(patientId: string): Promise<PreeclampsiaVitalsResponseDto[]> {
    const predictions = await this.preeclampsiaVitalsModel
      .find({ patientId })
      .sort({ createdAt: -1 })
      .exec();
    
    if (!predictions || predictions.length === 0) {
      throw new NotFoundException(`No predictions found for patient ID: ${patientId}`);
    }

    return predictions.map(this.mapToResponseDto);
  }

  async getLatestPredictionByPatientId(patientId: string): Promise<PreeclampsiaVitalsResponseDto> {
    const prediction = await this.preeclampsiaVitalsModel
      .findOne({ patientId })
      .sort({ createdAt: -1 })  // Sort descending (newest first)
      .exec();
    
    if (!prediction) {
      throw new NotFoundException(`No predictions found for patient ID: ${patientId}`);
    }

    return this.mapToResponseDto(prediction);
  }

  // Get the earliest (oldest) prediction for a patient
  async getEarliestPredictionByPatientId(patientId: string): Promise<PreeclampsiaVitalsResponseDto> {
    const prediction = await this.preeclampsiaVitalsModel
      .findOne({ patientId })
      .sort({ createdAt: 1 })  // Sort ascending (oldest first)
      .exec();
    
    if (!prediction) {
      throw new NotFoundException(`No predictions found for patient ID: ${patientId}`);
    }

    return this.mapToResponseDto(prediction);
  }

  async updatePrediction(
    patientId: string,
    updatePreeclampsiaVitalsDto: UpdatePreeclampsiaVitalsDto,
  ): Promise<PreeclampsiaVitalsResponseDto> {
    let updateFields: any = { ...updatePreeclampsiaVitalsDto };

    // Recalculate MAP and status if BP values or protein urine are updated
    if (updatePreeclampsiaVitalsDto.systolicBP || updatePreeclampsiaVitalsDto.diastolicBP || updatePreeclampsiaVitalsDto.proteinUrine) {
      // Get the latest record for this patient to use as base for calculations
      const existing = await this.preeclampsiaVitalsModel
        .findOne({ patientId })
        .sort({ createdAt: -1 })
        .exec();
      
      if (!existing) {
        throw new NotFoundException(`Prediction not found for patient ID: ${patientId}`);
      }

      const systolicBP = updatePreeclampsiaVitalsDto.systolicBP || existing.systolicBP;
      const diastolicBP = updatePreeclampsiaVitalsDto.diastolicBP || existing.diastolicBP;
      const proteinUrine = updatePreeclampsiaVitalsDto.proteinUrine || existing.proteinUrine;

      updateFields.map = this.calculateMAP(systolicBP, diastolicBP);
      updateFields.status = this.determineStatus(updateFields.map, proteinUrine);
    }

    // Update the latest record for this patient
    const updatedPrediction = await this.preeclampsiaVitalsModel
      .findOneAndUpdate(
        { patientId }, 
        updateFields, 
        { 
          new: true,
          sort: { createdAt: -1 }  // Ensure we're updating the latest record
        }
      )
      .exec();

    if (!updatedPrediction) {
      throw new NotFoundException(`Prediction not found for patient ID: ${patientId}`);
    }

    return this.mapToResponseDto(updatedPrediction);
  }

  async deletePredictionsByPatientId(patientId: string): Promise<{ message: string }> {
    const result = await this.preeclampsiaVitalsModel.deleteMany({ patientId }).exec();
    
    if (result.deletedCount === 0) {
      throw new NotFoundException(`No predictions found for patient ID: ${patientId}`);
    }

    return { message: `Successfully deleted ${result.deletedCount} prediction(s) for patient ID: ${patientId}` };
  }

  private mapToResponseDto(prediction: PreeclampsiaVitals): PreeclampsiaVitalsResponseDto {
    return {
      patientId: prediction.patientId,
      systolicBP: prediction.systolicBP,
      diastolicBP: prediction.diastolicBP,
      proteinUrine: prediction.proteinUrine,
      map: prediction.map,
      status: prediction.status,
      createdAt: prediction.createdAt,
      updatedAt: prediction.updatedAt,
    };
  }
}