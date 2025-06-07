import {
  Controller,
  Get,
  Post,
  Body,
  ValidationPipe,
  UsePipes,
  HttpStatus,
  HttpCode,
  HttpException,
} from '@nestjs/common';
import { PatientHardwareService } from './patient-hardware.service';
import { CreatePatientHardwareDto } from 'src/users/dto/create-patient-hardware.dto';
import { CreatePredictionHardwareDto } from 'src/users/dto/create-prediction-hardware.dto';

@Controller('patients-hardware')
export class PatientHardwareController {
  constructor(private readonly patientHardwareService: PatientHardwareService) {}

  // POST /patients-hardware - Create patient hardware record
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(new ValidationPipe())
  async create(@Body() createPatientHardwareDto: CreatePatientHardwareDto) {
    const patient = await this.patientHardwareService.create(createPatientHardwareDto);
    return {
      statusCode: HttpStatus.CREATED,
      message: 'Patient hardware record created successfully',
      data: patient,
      timestamp: new Date().toISOString(),
    };
  }

  // GET /patients-hardware - Get the latest patient hardware record
  @Get()
  async getLatest() {
    const patient = await this.patientHardwareService.getLatestPatient();
        
    if (!patient) {
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: 'No patient hardware records found',
        data: null,
      };
    }

    return {
      statusCode: HttpStatus.OK,
      message: 'Latest patient hardware record retrieved successfully',
      data: patient,
    };
  }

  // POST /patients-hardware/predictions - Create prediction hardware record
  @Post('predictions')
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(new ValidationPipe())
  async createPrediction(@Body() createPredictionHardwareDto: CreatePredictionHardwareDto) {
    try {
      const result = await this.patientHardwareService.createPrediction(createPredictionHardwareDto);
      
      return {
        statusCode: HttpStatus.CREATED,
        message: 'Prediction hardware record created successfully',
        data: {
          ...result.prediction, // Use the prediction object directly
          patient_name: result.patient_name,
        },
        patient_name: result.patient_name, // Also include at root level for easy access
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      throw new HttpException(
        {
          statusCode: HttpStatus.BAD_REQUEST,
          message: error.message || 'Failed to create prediction',
          timestamp: new Date().toISOString(),
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  // GET /patients-hardware/predictions - Get the latest prediction hardware record
  @Get('predictions')
  async getLatestPrediction() {
    const result = await this.patientHardwareService.getLatestPrediction();
        
    if (!result) {
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: 'No prediction hardware records found',
        data: null,
        patient_name: null,
      };
    }

    return {
      statusCode: HttpStatus.OK,
      message: 'Latest prediction hardware record retrieved successfully',
      data: {
        ...result.prediction, // Spread the prediction object directly
        patient_name: result.patient_name,
      },
      patient_name: result.patient_name, // Also include at root level for easy access
    };
  }
}