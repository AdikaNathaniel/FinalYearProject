import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Put,
  Delete,
  HttpCode,
  HttpStatus
} from '@nestjs/common';
import { HeltecEsp32PredictionsService } from './heltec-esp32-predictions.service';
import { CreatePreeclampsiaVitalsDto } from 'src/users/dto/create-preeclampsia-vitals.dto';
import { UpdatePreeclampsiaVitalsDto } from 'src/users/dto/update-preeclampsia-vitals.dto';
import { PreeclampsiaVitalsResponseDto } from 'src/users/dto/preeclampsia-vitals-response.dto';

@Controller('heltec-esp32-predictions')
export class HeltecEsp32PredictionsController {
  constructor(
    private readonly heltecEsp32PredictionsService: HeltecEsp32PredictionsService
  ) {}

  @Post()
  async createPrediction(
    @Body() createPreeclampsiaVitalsDto: CreatePreeclampsiaVitalsDto
  ): Promise<PreeclampsiaVitalsResponseDto> {
    return this.heltecEsp32PredictionsService.createPrediction(createPreeclampsiaVitalsDto);
  }

  @Get()
  async getAllPredictions(): Promise<PreeclampsiaVitalsResponseDto[]> {
    return this.heltecEsp32PredictionsService.getAllPredictions();
  }

  // Get all predictions for a specific patient (sorted by newest first)
  @Get('patient/:patientId/all')
  async getAllPredictionsByPatientId(
    @Param('patientId') patientId: string
  ): Promise<PreeclampsiaVitalsResponseDto[]> {
    return this.heltecEsp32PredictionsService.getPredictionsByPatientId(patientId);
  }

  // Get the latest (most recent) prediction for a patient
  @Get('patient/:patientId/latest')
  async getLatestPredictionByPatientId(
    @Param('patientId') patientId: string
  ): Promise<PreeclampsiaVitalsResponseDto> {
    return this.heltecEsp32PredictionsService.getLatestPredictionByPatientId(patientId);
  }

  // Get the earliest (oldest) prediction for a patient
  @Get('patient/:patientId/earliest')
  async getEarliestPredictionByPatientId(
    @Param('patientId') patientId: string
  ): Promise<PreeclampsiaVitalsResponseDto> {
    return this.heltecEsp32PredictionsService.getEarliestPredictionByPatientId(patientId);
  }

  // Default endpoint - returns all predictions for the patient (for backward compatibility)
  @Get('patient/:patientId')
  async getPredictionsByPatientId(
    @Param('patientId') patientId: string
  ): Promise<PreeclampsiaVitalsResponseDto[]> {
    return this.heltecEsp32PredictionsService.getPredictionsByPatientId(patientId);
  }

  @Put('patient/:patientId')
  async updatePrediction(
    @Param('patientId') patientId: string,
    @Body() updatePreeclampsiaVitalsDto: UpdatePreeclampsiaVitalsDto
  ): Promise<PreeclampsiaVitalsResponseDto> {
    return this.heltecEsp32PredictionsService.updatePrediction(patientId, updatePreeclampsiaVitalsDto);
  }

  @Delete('patient/:patientId')
  @HttpCode(HttpStatus.OK)
  async deletePredictionsByPatientId(
    @Param('patientId') patientId: string  // Removed ParseUUIDPipe since your IDs aren't UUIDs
  ): Promise<{ message: string }> {
    return this.heltecEsp32PredictionsService.deletePredictionsByPatientId(patientId);
  }
}