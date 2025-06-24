import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Vital } from 'src/shared/schema/vital.schema';
import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
import { VitalDto } from 'src/users/dto/vital.dto';
import { Kafka, Consumer, EachMessagePayload } from 'kafkajs';

@Injectable()
export class VitalsService implements OnModuleInit {
  private kafkaConsumer: Consumer;

  constructor(
    @InjectModel(Vital.name) private vitalModel: Model<Vital>,
  ) {
    // Configure Kafka consumer
    const kafka = new Kafka({
      clientId: 'vitals-service',
      brokers: ['localhost:9092'],
    });

    this.kafkaConsumer = kafka.consumer({ groupId: 'vitals-consumer' });
  }

  async onModuleInit() {
    await this.connectKafkaConsumer();
  }

  private async connectKafkaConsumer() {
    try {
      await this.kafkaConsumer.connect();
      await this.kafkaConsumer.subscribe({ topic: 'vitals-updates', fromBeginning: false });
      
      await this.kafkaConsumer.run({
        eachMessage: async ({ message }: EachMessagePayload) => {
          const vitalData = JSON.parse(message.value.toString());
          console.log('📩 [Kafka] Received vital data:', vitalData);
          
          // Process and store the Kafka message
          await this.processKafkaVital(vitalData);
        },
      });
      
      console.log('✅ [Kafka] Consumer connected and subscribed');
    } catch (error) {
      console.error('❌ [Kafka] Consumer connection error:', error);
    }
  }

  private async processKafkaVital(vitalData: any) {
    try {
      // Convert Kafka message to CreateVitalDto format
      const createVitalDto: CreateVitalDto = {
        patientId: vitalData.patientId,
        systolic: vitalData.systolic,
        diastolic: vitalData.diastolic,
        map: vitalData.map,
        proteinuria: vitalData.proteinuria,
        temperature: vitalData.temperature,
        heartRate: vitalData.heartRate,
        glucose: vitalData.glucose,
        spo2: vitalData.spo2,
        severity: vitalData.severity,
        rationale: vitalData.rationale,
        mlSeverity: vitalData.mlSeverity,
        mlProbability: vitalData.mlProbability,
        timestamp: new Date(vitalData.timestamp),
      };

      // Save to MongoDB
      await this.create(createVitalDto);
    } catch (error) {
      console.error('❌ Error processing Kafka message:', error);
    }
  }

  async create(createVitalDto: CreateVitalDto): Promise<VitalDto> {
    try {
      // Calculate MAP if not provided
      const map = createVitalDto.map || 
        (createVitalDto.systolic + 2 * createVitalDto.diastolic) / 3;

      const createdVital = new this.vitalModel({
        ...createVitalDto,
        map,
        createdAt: createVitalDto.timestamp || new Date()
      });

      const savedVital = await createdVital.save();
      console.log('✅ [MongoDB] Saved vital:', savedVital._id);
      return this.mapToDto(savedVital);
    } catch (error) {
      console.error('❌ [MongoDB] Save error:', error.message);
      throw error;
    }
  }

  async findAll(): Promise<VitalDto[]> {
    try {
      const vitals = await this.vitalModel.find()
        .sort({ createdAt: -1 })
        .lean()
        .exec();

      console.log(`📊 [MongoDB] Found ${vitals.length} vitals`);
      return vitals.map(this.mapToDto);
    } catch (error) {
      console.error('❌ [MongoDB] Find error:', error.message);
      throw error;
    }
  }

  async findByPatientId(patientId: string): Promise<VitalDto[]> {
    try {
      const vitals = await this.vitalModel.find({ patientId })
        .sort({ createdAt: -1 })
        .lean()
        .exec();
      return vitals.map(this.mapToDto);
    } catch (error) {
      console.error('❌ [MongoDB] Find by patientId error:', error.message);
      throw error;
    }
  }

  private mapToDto(vital: any): VitalDto {
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
      glucose: vital.glucose,
      rationale: vital.rationale,
      mlSeverity: vital.mlSeverity,
      mlProbability: vital.mlProbability,
      createdAt: vital.createdAt
    };
  }
}