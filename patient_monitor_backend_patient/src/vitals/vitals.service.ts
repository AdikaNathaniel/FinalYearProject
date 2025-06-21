import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Vital } from 'src/shared/schema/vital.schema';
import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
import { VitalDto } from 'src/users/dto/vital.dto';
import { KafkaService } from 'src/kafka/kafka.service';

@Injectable()
export class VitalsService {
  constructor(
    @InjectModel(Vital.name) private vitalModel: Model<Vital>,
    private readonly kafkaService: KafkaService
  ) {}

  async create(createVitalDto: CreateVitalDto): Promise<VitalDto> {
    // Calculate MAP if not provided
    const map = createVitalDto.map || 
      (createVitalDto.systolic + 2 * createVitalDto.diastolic) / 3;
    
    const createdVital = new this.vitalModel({
      ...createVitalDto,
      map,
      createdAt: createVitalDto.timestamp || new Date()
    });
    
    const vital = await createdVital.save();
    
    // Notify via Kafka that new vital was created
    await this.kafkaService.sendMessage('vitals-updates', this.mapToDto(vital));
    
    return this.mapToDto(vital);
  }

  async findAll(): Promise<VitalDto[]> {
    const vitals = await this.vitalModel.find().sort({ createdAt: -1 }).exec();
    return vitals.map(this.mapToDto);
  }

  async findByPatientId(patientId: string): Promise<VitalDto[]> {
    const vitals = await this.vitalModel.find({ patientId })
      .sort({ createdAt: -1 })
      .exec();
    return vitals.map(this.mapToDto);
  }

  private mapToDto(vital: Vital): VitalDto {
    return {
      id: vital._id.toString(),
      patientId: vital.patientId,
      systolic: vital.systolic,
      diastolic: vital.diastolic,
      map: vital.map,
      proteinuria: vital.proteinuria,
      temperature: vital.temperature,
      heartRate: vital.heartRate,
      spo2: vital.spo2,
      severity: vital.severity,
      rationale: vital.rationale,
      mlSeverity: vital.mlSeverity,
      mlProbability: vital.mlProbability,
      createdAt: vital.createdAt
    };
  }
}