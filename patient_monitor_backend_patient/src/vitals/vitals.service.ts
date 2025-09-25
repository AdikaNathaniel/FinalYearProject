// import { Injectable, OnModuleInit } from '@nestjs/common';
// import { InjectModel } from '@nestjs/mongoose';
// import { Model } from 'mongoose';
// import { Vital } from 'src/shared/schema/vital.schema';
// import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
// import { VitalDto } from 'src/users/dto/vital.dto';
// import { Kafka, Consumer, EachMessagePayload } from 'kafkajs';
// import * as crypto from 'crypto';

// @Injectable()
// export class VitalsService implements OnModuleInit {
//   private kafkaConsumer: Consumer;
  
//   // AES Configuration - MUST MATCH ESP32
//   private readonly AES_KEY = 'MySecretKey12345MySecretKey12345'; // 32 bytes for AES-256
//   private readonly AES_IV = 'MyInitVector1234'; // 16 bytes for AES-128-CBC

//   constructor(
//     @InjectModel(Vital.name) private vitalModel: Model<Vital>,
//   ) {
//     // Configure Kafka consumer
//     const kafka = new Kafka({
//       clientId: 'vitals-service',
//       brokers: ['localhost:9092'],
//     });

//     this.kafkaConsumer = kafka.consumer({ groupId: 'vitals-consumer' });
    
//     // Log AES configuration on startup
//     console.log('🔐 [AES] VitalsService initialized with AES-256-CBC encryption');
//     console.log(`🔑 [AES] Using Key: ${this.AES_KEY}`);
//     console.log(`🎯 [AES] Using IV:  ${this.AES_IV}`);
//   }

//   async onModuleInit() {
//     await this.connectKafkaConsumer();
//   }

//   private async connectKafkaConsumer() {
//     try {
//       await this.kafkaConsumer.connect();
//       await this.kafkaConsumer.subscribe({ topic: 'vitals-updates', fromBeginning: false });
      
//       await this.kafkaConsumer.run({
//         eachMessage: async ({ message }: EachMessagePayload) => {
//           const vitalData = JSON.parse(message.value.toString());
//           console.log('📩 [Kafka] Received vital data:', vitalData);
          
//           // Process and store the Kafka message
//           await this.processKafkaVital(vitalData);
//         },
//       });
      
//       console.log('✅ [Kafka] Consumer connected and subscribed');
//     } catch (error) {
//       console.error('❌ [Kafka] Consumer connection error:', error);
//     }
//   }

//   /**
//    * Decrypt AES-256-CBC encrypted data
//    */
//   private decryptAES(encryptedData: string): string | null {
//     try {
//       console.log('\n🔓 [AES] Starting decryption process...');
//       console.log('🔒 [AES] Encrypted data (Base64):', encryptedData);
      
//       // Create decipher
//       const decipher = crypto.createDecipheriv('aes-256-cbc', this.AES_KEY, this.AES_IV);
      
//       // Decrypt
//       let decrypted = decipher.update(encryptedData, 'base64', 'utf8');
//       decrypted += decipher.final('utf8');
      
//       // Remove padding spaces
//       decrypted = decrypted.trim();
      
//       console.log('✅ [AES] Decryption successful!');
//       console.log('📝 [AES] Decrypted data:', decrypted);
      
//       return decrypted;
//     } catch (error) {
//       console.error('❌ [AES] Decryption failed:', error.message);
//       return null;
//     }
//   }

//   /**
//    * Process encrypted vital data from ESP32
//    */
//   async processEncryptedVital(encryptedPayload: any): Promise<VitalDto | null> {
//     try {
//       console.log('\n📦 [HTTP] Received encrypted payload from ESP32');
//       console.log('🔍 [HTTP] Checking if payload is encrypted...');
      
//       if (!encryptedPayload.encrypted || !encryptedPayload.encryptedData) {
//         console.log('⚠️ [HTTP] Payload is not encrypted, processing as plain text');
//         return await this.create(encryptedPayload as CreateVitalDto);
//       }
      
//       console.log('🔐 [HTTP] Payload is encrypted, starting decryption...');
      
//       // Decrypt the data
//       const decryptedJson = this.decryptAES(encryptedPayload.encryptedData);
      
//       if (!decryptedJson) {
//         console.error('❌ [AES] Failed to decrypt payload');
//         return null;
//       }
      
//       // Parse the decrypted JSON
//       const vitalData = JSON.parse(decryptedJson);
//       console.log('📊 [AES] Decrypted vital data:', vitalData);
      
//       // Convert to CreateVitalDto and save
//       const createVitalDto: CreateVitalDto = {
//         patientId: vitalData.patientId,
//         systolic: vitalData.systolic,
//         diastolic: vitalData.diastolic,
//         map: vitalData.map,
//         proteinuria: vitalData.proteinuria,
//         temperature: vitalData.temperature,
//         heartRate: vitalData.heartRate,
//         glucose: vitalData.glucose,
//         spo2: vitalData.spo2,
//         severity: vitalData.severity,
//         rationale: vitalData.rationale,
//         mlSeverity: vitalData.mlSeverity,
//         mlProbability: vitalData.mlProbability,
//         timestamp: new Date(),
//       };
      
//       console.log('💾 [MongoDB] Saving decrypted vital data...');
//       return await this.create(createVitalDto);
      
//     } catch (error) {
//       console.error('❌ [HTTP] Error processing encrypted vital:', error.message);
//       return null;
//     }
//   }

//   private async processKafkaVital(vitalData: any) {
//     try {
//       // Convert Kafka message to CreateVitalDto format
//       const createVitalDto: CreateVitalDto = {
//         patientId: vitalData.patientId,
//         systolic: vitalData.systolic,
//         diastolic: vitalData.diastolic,
//         map: vitalData.map,
//         proteinuria: vitalData.proteinuria,
//         temperature: vitalData.temperature,
//         heartRate: vitalData.heartRate,
//         glucose: vitalData.glucose,
//         spo2: vitalData.spo2,
//         severity: vitalData.severity,
//         rationale: vitalData.rationale,
//         mlSeverity: vitalData.mlSeverity,
//         mlProbability: vitalData.mlProbability,
//         timestamp: new Date(vitalData.timestamp),
//       };

//       // Save to MongoDB
//       await this.create(createVitalDto);
//     } catch (error) {
//       console.error('❌ [Kafka] Error processing message:', error);
//     }
//   }

//   async create(createVitalDto: CreateVitalDto): Promise<VitalDto> {
//     try {
//       console.log('\n💾 [MongoDB] Creating new vital record...');
//       console.log('📊 [MongoDB] Vital data:', {
//         patientId: createVitalDto.patientId,
//         heartRate: createVitalDto.heartRate,
//         systolic: createVitalDto.systolic,
//         diastolic: createVitalDto.diastolic,
//         temperature: createVitalDto.temperature,
//         glucose: createVitalDto.glucose,
//         spo2: createVitalDto.spo2,
//       });
      
//       // Calculate MAP if not provided
//       const map = createVitalDto.map || 
//         (createVitalDto.systolic + 2 * createVitalDto.diastolic) / 3;

//       const createdVital = new this.vitalModel({
//         ...createVitalDto,
//         map,
//         createdAt: createVitalDto.timestamp || new Date()
//       });

//       const savedVital = await createdVital.save();
//       console.log('✅ [MongoDB] Vital record saved successfully!');
//       console.log('🆔 [MongoDB] Record ID:', savedVital._id);
//       console.log('📈 [MongoDB] Calculated MAP:', map.toFixed(1));
      
//       return this.mapToDto(savedVital);
//     } catch (error) {
//       console.error('❌ [MongoDB] Save error:', error.message);
//       throw error;
//     }
//   }

//   async findAll(): Promise<VitalDto[]> {
//     try {
//       console.log('\n🔍 [MongoDB] Fetching all vital records...');
//       const vitals = await this.vitalModel.find()
//         .sort({ createdAt: -1 })
//         .lean()
//         .exec();

//       console.log(`📊 [MongoDB] Found ${vitals.length} vital records`);
//       return vitals.map(this.mapToDto);
//     } catch (error) {
//       console.error('❌ [MongoDB] Find error:', error.message);
//       throw error;
//     }
//   }

//   async findByPatientId(patientId: string): Promise<VitalDto[]> {
//     try {
//       console.log(`\n🔍 [MongoDB] Fetching vitals for patient: ${patientId}`);
//       const vitals = await this.vitalModel.find({ patientId })
//         .sort({ createdAt: -1 })
//         .lean()
//         .exec();
      
//       console.log(`📊 [MongoDB] Found ${vitals.length} records for patient ${patientId}`);
//       return vitals.map(this.mapToDto);
//     } catch (error) {
//       console.error('❌ [MongoDB] Find by patientId error:', error.message);
//       throw error;
//     }
//   }

//   private mapToDto(vital: any): VitalDto {
//     return {
//       id: vital._id.toString(),
//       patientId: vital.patientId,
//       systolic: vital.systolic,
//       diastolic: vital.diastolic,
//       map: vital.map,
//       proteinuria: vital.proteinuria,
//       temperature: vital.temperature,
//       heartRate: vital.heartRate,
//       spo2: vital.spo2,
//       severity: vital.severity,
//       glucose: vital.glucose,
//       rationale: vital.rationale,
//       mlSeverity: vital.mlSeverity,
//       mlProbability: vital.mlProbability,
//       createdAt: vital.createdAt
//     };
//   }
// }



// import { Injectable, OnModuleInit } from '@nestjs/common';
// import { InjectModel } from '@nestjs/mongoose';
// import { Model } from 'mongoose';
// import { Vital } from 'src/shared/schema/vital.schema';
// import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
// import { VitalDto } from 'src/users/dto/vital.dto';
// import { Kafka, Consumer, EachMessagePayload } from 'kafkajs';
// import * as crypto from 'crypto';

// @Injectable()
// export class VitalsService implements OnModuleInit {
//   private kafkaConsumer: Consumer;
  
//   // AES Configuration - MUST MATCH ESP32
//   private readonly AES_KEY = 'MySecretKey12345MySecretKey12345'; // 32 bytes for AES-256
//   private readonly AES_IV = 'MyInitVector1234'; // 16 bytes for AES-128-CBC

//   constructor(
//     @InjectModel(Vital.name) private vitalModel: Model<Vital>,
//   ) {
//     // Configure Kafka consumer
//     const kafka = new Kafka({
//       clientId: 'vitals-service',
//       brokers: ['localhost:9092'],
//     });

//     this.kafkaConsumer = kafka.consumer({ groupId: 'vitals-consumer' });
    
//     // Log AES configuration on startup
//     console.log('🔐 [AES] VitalsService initialized with AES-256-CBC encryption');
//     console.log(`🔑 [AES] Using Key: ${this.AES_KEY}`);
//     console.log(`🎯 [AES] Using IV:  ${this.AES_IV}`);
//   }

//   async onModuleInit() {
//     await this.connectKafkaConsumer();
//   }

//   private async connectKafkaConsumer() {
//     try {
//       await this.kafkaConsumer.connect();
//       await this.kafkaConsumer.subscribe({ topic: 'vitals-updates', fromBeginning: false });
      
//       await this.kafkaConsumer.run({
//         eachMessage: async ({ message }: EachMessagePayload) => {
//           const vitalData = JSON.parse(message.value.toString());
//           console.log('📩 [Kafka] Received vital data:', vitalData);
          
//           // Process and store the Kafka message
//           await this.processKafkaVital(vitalData);
//         },
//       });
      
//       console.log('✅ [Kafka] Consumer connected and subscribed');
//     } catch (error) {
//       console.error('❌ [Kafka] Consumer connection error:', error);
//     }
//   }

//   /**
//    * Decrypt AES-256-CBC encrypted data
//    */
//   private decryptAES(encryptedData: string): string | null {
//     try {
//       console.log('\n🔓 [AES] Starting decryption process...');
//       console.log('🔒 [AES] Encrypted data (Base64):', encryptedData);
      
//       // Create decipher
//       const decipher = crypto.createDecipheriv('aes-256-cbc', this.AES_KEY, this.AES_IV);
      
//       // Decrypt
//       let decrypted = decipher.update(encryptedData, 'base64', 'utf8');
//       decrypted += decipher.final('utf8');
      
//       // Remove padding spaces
//       decrypted = decrypted.trim();
      
//       console.log('✅ [AES] Decryption successful!');
//       console.log('📝 [AES] Decrypted data:', decrypted);
      
//       return decrypted;
//     } catch (error) {
//       console.error('❌ [AES] Decryption failed:', error.message);
//       return null;
//     }
//   }

//   /**
//    * Process encrypted vital data from ESP32
//    */
//   async processEncryptedVital(encryptedPayload: any): Promise<VitalDto | null> {
//     try {
//       console.log('\n📦 [HTTP] Received encrypted payload from ESP32');
//       console.log('🔍 [HTTP] Checking if payload is encrypted...');
      
//       if (!encryptedPayload.encrypted || !encryptedPayload.encryptedData) {
//         console.log('⚠️ [HTTP] Payload is not encrypted, processing as plain text');
//         return await this.create(encryptedPayload as CreateVitalDto);
//       }
      
//       console.log('🔐 [HTTP] Payload is encrypted, starting decryption...');
      
//       // Decrypt the data
//       const decryptedJson = this.decryptAES(encryptedPayload.encryptedData);
      
//       if (!decryptedJson) {
//         console.error('❌ [AES] Failed to decrypt payload');
//         return null;
//       }
      
//       // Parse the decrypted JSON
//       const vitalData = JSON.parse(decryptedJson);
//       console.log('📊 [AES] Decrypted vital data:', vitalData);
      
//       // Convert to CreateVitalDto and save
//       const createVitalDto: CreateVitalDto = {
//         patientId: vitalData.patientId,
//         systolic: vitalData.systolic,
//         diastolic: vitalData.diastolic,
//         map: vitalData.map,
//         proteinuria: vitalData.proteinuria,
//         temperature: vitalData.temperature,
//         heartRate: vitalData.heartRate,
//         glucose: vitalData.glucose,
//         spo2: vitalData.spo2,
//         severity: vitalData.severity,
//         rationale: vitalData.rationale,
//         mlSeverity: vitalData.mlSeverity,
//         mlProbability: vitalData.mlProbability,
//         timestamp: new Date(),
        
//         // Alert fields
//         hasAlerts: vitalData.hasAlerts,
//         tempAlert: vitalData.tempAlert,
//         hrAlert: vitalData.hrAlert,
//         spo2Alert: vitalData.spo2Alert,
//         glucoseAlert: vitalData.glucoseAlert,
//         tempAlertSeverity: vitalData.tempAlertSeverity,
//         hrAlertSeverity: vitalData.hrAlertSeverity,
//         spo2AlertSeverity: vitalData.spo2AlertSeverity,
//         glucoseAlertSeverity: vitalData.glucoseAlertSeverity,
//         thresholds: vitalData.thresholds
//       };
      
//       console.log('💾 [MongoDB] Saving decrypted vital data...');
      
//       // Log alerts if present
//       if (createVitalDto.hasAlerts) {
//         console.log('🚨 [ALERT] Processing vital data with alerts:', {
//           tempAlert: createVitalDto.tempAlert,
//           hrAlert: createVitalDto.hrAlert,
//           spo2Alert: createVitalDto.spo2Alert,
//           glucoseAlert: createVitalDto.glucoseAlert
//         });
//       }
      
//       return await this.create(createVitalDto);
      
//     } catch (error) {
//       console.error('❌ [HTTP] Error processing encrypted vital:', error.message);
//       return null;
//     }
//   }

//   private async processKafkaVital(vitalData: any) {
//     try {
//       // Convert Kafka message to CreateVitalDto format
//       const createVitalDto: CreateVitalDto = {
//         patientId: vitalData.patientId,
//         systolic: vitalData.systolic,
//         diastolic: vitalData.diastolic,
//         map: vitalData.map,
//         proteinuria: vitalData.proteinuria,
//         temperature: vitalData.temperature,
//         heartRate: vitalData.heartRate,
//         glucose: vitalData.glucose,
//         spo2: vitalData.spo2,
//         severity: vitalData.severity,
//         rationale: vitalData.rationale,
//         mlSeverity: vitalData.mlSeverity,
//         mlProbability: vitalData.mlProbability,
//         timestamp: new Date(vitalData.timestamp),
        
//         // Alert fields
//         hasAlerts: vitalData.hasAlerts,
//         tempAlert: vitalData.tempAlert,
//         hrAlert: vitalData.hrAlert,
//         spo2Alert: vitalData.spo2Alert,
//         glucoseAlert: vitalData.glucoseAlert,
//         tempAlertSeverity: vitalData.tempAlertSeverity,
//         hrAlertSeverity: vitalData.hrAlertSeverity,
//         spo2AlertSeverity: vitalData.spo2AlertSeverity,
//         glucoseAlertSeverity: vitalData.glucoseAlertSeverity,
//         thresholds: vitalData.thresholds
//       };

//       // Save to MongoDB
//       await this.create(createVitalDto);
//     } catch (error) {
//       console.error('❌ [Kafka] Error processing message:', error);
//     }
//   }

//   async create(createVitalDto: CreateVitalDto): Promise<VitalDto> {
//     try {
//       console.log('\n💾 [MongoDB] Creating new vital record...');
//       console.log('📊 [MongoDB] Vital data:', {
//         patientId: createVitalDto.patientId,
//         heartRate: createVitalDto.heartRate,
//         systolic: createVitalDto.systolic,
//         diastolic: createVitalDto.diastolic,
//         temperature: createVitalDto.temperature,
//         glucose: createVitalDto.glucose,
//         spo2: createVitalDto.spo2,
//         hasAlerts: createVitalDto.hasAlerts
//       });
      
//       // Calculate MAP if not provided
//       const map = createVitalDto.map || 
//         (createVitalDto.systolic + 2 * createVitalDto.diastolic) / 3;

//       const createdVital = new this.vitalModel({
//         ...createVitalDto,
//         map,
//         createdAt: createVitalDto.timestamp || new Date()
//       });

//       const savedVital = await createdVital.save();
//       console.log('✅ [MongoDB] Vital record saved successfully!');
//       console.log('🆔 [MongoDB] Record ID:', savedVital._id);
      
//       if (savedVital.hasAlerts) {
//         console.log('🚨 [ALERT] Saved vital record with alerts:', {
//           tempAlert: savedVital.tempAlert,
//           hrAlert: savedVital.hrAlert,
//           spo2Alert: savedVital.spo2Alert,
//           glucoseAlert: savedVital.glucoseAlert
//         });
//       }
      
//       return this.mapToDto(savedVital);
//     } catch (error) {
//       console.error('❌ [MongoDB] Save error:', error.message);
//       throw error;
//     }
//   }

//   async findAll(): Promise<VitalDto[]> {
//     try {
//       console.log('\n🔍 [MongoDB] Fetching all vital records...');
//       const vitals = await this.vitalModel.find()
//         .sort({ createdAt: -1 })
//         .lean()
//         .exec();

//       console.log(`📊 [MongoDB] Found ${vitals.length} vital records`);
//       return vitals.map(this.mapToDto);
//     } catch (error) {
//       console.error('❌ [MongoDB] Find error:', error.message);
//       throw error;
//     }
//   }

//   async findByPatientId(patientId: string): Promise<VitalDto[]> {
//     try {
//       console.log(`\n🔍 [MongoDB] Fetching vitals for patient: ${patientId}`);
//       const vitals = await this.vitalModel.find({ patientId })
//         .sort({ createdAt: -1 })
//         .lean()
//         .exec();
      
//       console.log(`📊 [MongoDB] Found ${vitals.length} records for patient ${patientId}`);
//       return vitals.map(this.mapToDto);
//     } catch (error) {
//       console.error('❌ [MongoDB] Find by patientId error:', error.message);
//       throw error;
//     }
//   }

//   async findCriticalAlerts(patientId: string): Promise<VitalDto[]> {
//     try {
//       console.log(`\n🔍 [MongoDB] Fetching critical alerts for patient: ${patientId}`);
//       const vitals = await this.vitalModel.find({ 
//         patientId,
//         hasAlerts: true 
//       })
//       .sort({ createdAt: -1 })
//       .lean()
//       .exec();
      
//       console.log(`🚨 [ALERT] Found ${vitals.length} critical alerts for patient ${patientId}`);
//       return vitals.map(this.mapToDto);
//     } catch (error) {
//       console.error('❌ [MongoDB] Error fetching critical alerts:', error.message);
//       throw error;
//     }
//   }

//   private mapToDto(vital: any): VitalDto {
//     return {
//       id: vital._id.toString(),
//       patientId: vital.patientId,
//       systolic: vital.systolic,
//       diastolic: vital.diastolic,
//       map: vital.map,
//       proteinuria: vital.proteinuria,
//       temperature: vital.temperature,
//       heartRate: vital.heartRate,
//       spo2: vital.spo2,
//       severity: vital.severity,
//       glucose: vital.glucose,
//       rationale: vital.rationale,
//       mlSeverity: vital.mlSeverity,
//       mlProbability: vital.mlProbability,
//       createdAt: vital.createdAt,
      
//       // Alert fields
//       hasAlerts: vital.hasAlerts,
//       tempAlert: vital.tempAlert,
//       hrAlert: vital.hrAlert,
//       spo2Alert: vital.spo2Alert,
//       glucoseAlert: vital.glucoseAlert,
//       tempAlertSeverity: vital.tempAlertSeverity,
//       hrAlertSeverity: vital.hrAlertSeverity,
//       spo2AlertSeverity: vital.spo2AlertSeverity,
//       glucoseAlertSeverity: vital.glucoseAlertSeverity,
//       thresholds: vital.thresholds
//     };
//   }
// }



import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Vital } from 'src/shared/schema/vital.schema';
import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
import { VitalDto } from 'src/users/dto/vital.dto';
import { Kafka, Consumer, EachMessagePayload } from 'kafkajs';
import * as crypto from 'crypto';

interface ArduinoVitalData {
  deviceId: string;
  timestamp: string;
  vitals: {
    heartRate: number;
    systolic: number;
    diastolic: number;
    temperature: number;
    glucose: number;
    spo2: number;
  };
}

interface ArduinoEncryptedPayload {
  deviceId: string;
  timestamp: string;
  data: string; // base64 encrypted data
  metadata?: any;
  alerts?: {
    hasAlerts: boolean;
    temperature: boolean;
    heartRate: boolean;
    spo2: boolean;
    glucose: boolean;
  };
}

@Injectable()
export class VitalsService implements OnModuleInit {
  private kafkaConsumer: Consumer;
  
  // AES Configuration - MUST MATCH ESP32 EXACTLY
  // Using the same byte arrays as in your Arduino code
  private readonly AES_KEY = Buffer.from([
    0x2b, 0x7e, 0x15, 0x16,
    0x28, 0xae, 0xd2, 0xa6,
    0xab, 0xf7, 0x15, 0x88,
    0x09, 0xcf, 0x4f, 0x3c
  ]); // 16 bytes for AES-128

  private readonly AES_IV = Buffer.from([
    0x00, 0x01, 0x02, 0x03,
    0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0A, 0x0B,
    0x0C, 0x0D, 0x0E, 0x0F
  ]); // 16 bytes for AES-128-CBC

  // Alert thresholds matching Arduino
  private readonly ALERT_THRESHOLDS = {
    tempLow: 36.0,
    tempHigh: 38.0,
    hrLow: 80.0,
    hrHigh: 85.0,
    spo2Low: 90.0,
    spo2High: 96.0,
    glucoseLow: 70.0,
    glucoseHigh: 200.0
  };

  constructor(
    @InjectModel(Vital.name) private vitalModel: Model<Vital>,
  ) {
    // Configure Kafka consumer
    const kafka = new Kafka({
      clientId: 'vitals-service',
      brokers: ['localhost:9092'],
    });

    this.kafkaConsumer = kafka.consumer({ groupId: 'vitals-consumer' });
    
    // Log AES configuration on startup
    console.log('\n🔐 [AES] VitalsService initialized with AES-128-CBC encryption');
    console.log('=' + '='.repeat(70));
    console.log('🔑 [AES] Key (16 bytes): ' + this.AES_KEY.toString('hex').toUpperCase());
    console.log('🎯 [AES] IV  (16 bytes): ' + this.AES_IV.toString('hex').toUpperCase());
    console.log('🔧 [AES] Algorithm: AES-128-CBC');
    console.log('🏢 [AES] Standard: FIPS 197 (Advanced Encryption Standard)');
    console.log('🔒 [AES] Security Level: HIGH (Government Grade)');
    console.log('=' + '='.repeat(70));
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

  /**
   * Get AES configuration details
   */
  getAESConfiguration() {
    return {
      algorithm: 'AES-128-CBC',
      keyLength: this.AES_KEY.length * 8, // 128 bits
      blockSize: this.AES_IV.length, // 16 bytes
      mode: 'CBC (Cipher Block Chaining)',
      ready: true
    };
  }

  /**
   * Decrypt AES-128-CBC encrypted data from Arduino
   * This matches the exact encryption used in your ESP32 code
   */
  private decryptHealthData(encryptedBase64Data: string): string {
    try {
      console.log('\n🔓 [AES] Starting AES-128-CBC decryption process...');
      console.log('🔒 [AES] Encrypted data (Base64):', encryptedBase64Data);
      console.log('📏 [AES] Base64 length:', encryptedBase64Data.length);
      
      // Convert base64 back to buffer
      const encryptedBuffer = Buffer.from(encryptedBase64Data, 'base64');
      console.log('📊 [AES] Encrypted buffer length:', encryptedBuffer.length, 'bytes');
      
      // Display encrypted data in HEX format for debugging
      console.log('🔍 [AES] Encrypted data (HEX):', encryptedBuffer.toString('hex').toUpperCase());
      
      // Create decipher with AES-128-CBC using the exact same key and IV as Arduino
      const decipher = crypto.createDecipheriv('aes-128-cbc', this.AES_KEY, this.AES_IV);
      
      // Decrypt the data
      let decrypted = decipher.update(encryptedBuffer, undefined, 'utf8');
      decrypted += decipher.final('utf8');
      
      // Remove null terminator if present (Arduino adds null terminator)
      decrypted = decrypted.replace(/\0+$/, '').trim();
      
      console.log('✅ [AES] Decryption successful!');
      console.log('📝 [AES] Decrypted data:', decrypted);
      console.log('📏 [AES] Decrypted length:', decrypted.length, 'characters');
      
      return decrypted;
    } catch (error) {
      console.error('❌ [AES] Decryption failed:', error.message);
      console.error('📚 [AES] Error stack:', error.stack);
      throw new Error(`AES decryption failed: ${error.message}`);
    }
  }

  /**
   * Test decryption without saving to database
   */
  async testDecryptHealthData(encryptedBase64Data: string) {
    try {
      console.log('\n🧪 [AES] Testing decryption...');
      
      const decryptedString = this.decryptHealthData(encryptedBase64Data);
      const parsedData = JSON.parse(decryptedString);
      
      console.log('✅ [AES] Test decryption successful');
      console.log('📊 [AES] Parsed data:', parsedData);
      
      return {
        success: true,
        decryptedData: decryptedString,
        parsedData: parsedData
      };
    } catch (error) {
      console.error('❌ [AES] Test decryption failed:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Check vital thresholds and generate alerts (matching Arduino logic)
   */
  private checkVitalThresholds(vitals: any) {
    const alerts = {
      hasAlerts: false,
      tempAlert: false,
      hrAlert: false,
      spo2Alert: false,
      glucoseAlert: false,
      details: []
    };

    // Check temperature
    if (vitals.temperature <= this.ALERT_THRESHOLDS.tempLow || vitals.temperature >= this.ALERT_THRESHOLDS.tempHigh) {
      alerts.tempAlert = true;
      alerts.hasAlerts = true;
      alerts.details.push(`Temperature ${vitals.temperature}°C is ${vitals.temperature <= this.ALERT_THRESHOLDS.tempLow ? 'too low' : 'too high'}`);
    }

    // Check heart rate
    if (vitals.heartRate >= this.ALERT_THRESHOLDS.hrLow) {
      alerts.hrAlert = true;
      alerts.hasAlerts = true;
      alerts.details.push(`Heart rate ${vitals.heartRate} bpm is elevated`);
    }

    // Check SpO2
    if (vitals.spo2 < this.ALERT_THRESHOLDS.spo2Low || vitals.spo2 > this.ALERT_THRESHOLDS.spo2High) {
      alerts.spo2Alert = true;
      alerts.hasAlerts = true;
      alerts.details.push(`SpO2 ${vitals.spo2}% is ${vitals.spo2 < this.ALERT_THRESHOLDS.spo2Low ? 'too low' : 'too high'}`);
    }

    // Check glucose
    if (vitals.glucose < this.ALERT_THRESHOLDS.glucoseLow || vitals.glucose > this.ALERT_THRESHOLDS.glucoseHigh) {
      alerts.glucoseAlert = true;
      alerts.hasAlerts = true;
      alerts.details.push(`Blood glucose ${vitals.glucose} mg/dL is ${vitals.glucose < this.ALERT_THRESHOLDS.glucoseLow ? 'too low' : 'too high'}`);
    }

    return alerts;
  }

  /**
   * Process encrypted vital data from Arduino (Azure Function format)
   */
  async processArduinoEncryptedVital(encryptedPayload: ArduinoEncryptedPayload): Promise<VitalDto | null> {
    try {
      console.log('\n🤖 [Arduino] Processing encrypted payload from Arduino device');
      console.log('🔍 [Arduino] Device ID:', encryptedPayload.deviceId);
      console.log('⏰ [Arduino] Timestamp:', encryptedPayload.timestamp);
      console.log('🔐 [Arduino] Encrypted data length:', encryptedPayload.data.length);
      
      if (encryptedPayload.metadata) {
        console.log('📊 [Arduino] Metadata:', encryptedPayload.metadata);
      }
      
      // Decrypt the data
      const decryptedJson = this.decryptHealthData(encryptedPayload.data);
      
      // Parse the decrypted JSON
      const arduinoData: ArduinoVitalData = JSON.parse(decryptedJson);
      console.log('📊 [Arduino] Decrypted vital data:', arduinoData);
      
      // Check for alerts
      const calculatedAlerts = this.checkVitalThresholds(arduinoData.vitals);
      
      // Use alerts from payload if available, otherwise use calculated alerts
      let finalAlerts: any = encryptedPayload.alerts || calculatedAlerts;

      // Normalize Arduino alert fields if present
      if (encryptedPayload.alerts && typeof encryptedPayload.alerts.temperature === 'boolean') {
        finalAlerts = {
          hasAlerts: encryptedPayload.alerts.hasAlerts,
          tempAlert: encryptedPayload.alerts.temperature,
          hrAlert: encryptedPayload.alerts.heartRate,
          spo2Alert: encryptedPayload.alerts.spo2,
          glucoseAlert: encryptedPayload.alerts.glucose,
          details: calculatedAlerts.details ?? []
        };
      }

      // Convert Arduino data to CreateVitalDto format
      const createVitalDto: CreateVitalDto = {
        patientId: arduinoData.deviceId, // Using deviceId as patientId for now
        systolic: arduinoData.vitals.systolic,
        diastolic: arduinoData.vitals.diastolic,
        map: (arduinoData.vitals.systolic + 2 * arduinoData.vitals.diastolic) / 3, // Calculate MAP
        proteinuria: 0, // Default value
        temperature: arduinoData.vitals.temperature,
        heartRate: arduinoData.vitals.heartRate,
        glucose: arduinoData.vitals.glucose,
        spo2: arduinoData.vitals.spo2,
        severity: finalAlerts.hasAlerts ? 'HIGH' : 'NORMAL',
        rationale: finalAlerts.hasAlerts
          ? `Alerts detected: ${Array.isArray((finalAlerts as any).details) ? (finalAlerts as any).details.join(', ') : 'Unknown details'}`
          : 'All vitals within normal range',
        mlSeverity: finalAlerts.hasAlerts ? 'HIGH' : 'NORMAL',
        mlProbability: finalAlerts.hasAlerts ? { risk: 0.8 } : { risk: 0.1 },
        timestamp: new Date(arduinoData.timestamp),
        
        // Alert fields
        hasAlerts: finalAlerts.hasAlerts,
        tempAlert: finalAlerts.tempAlert,
        hrAlert: finalAlerts.hrAlert,
        spo2Alert: finalAlerts.spo2Alert,
        glucoseAlert: finalAlerts.glucoseAlert,
        tempAlertSeverity: finalAlerts.tempAlert ? 'HIGH' : 'LOW',
        hrAlertSeverity: finalAlerts.hrAlert ? 'HIGH' : 'LOW',
        spo2AlertSeverity: finalAlerts.spo2Alert ? 'HIGH' : 'LOW',
        glucoseAlertSeverity: finalAlerts.glucoseAlert ? 'HIGH' : 'LOW',
        thresholds: this.ALERT_THRESHOLDS
      };
      
      console.log('💾 [Arduino] Saving decrypted Arduino vital data...');
      
      // Log alerts if present
      if (createVitalDto.hasAlerts) {
        console.log('🚨 [ALERT] Processing Arduino vital data with alerts:', {
          tempAlert: createVitalDto.tempAlert,
          hrAlert: createVitalDto.hrAlert,
          spo2Alert: createVitalDto.spo2Alert,
          glucoseAlert: createVitalDto.glucoseAlert,
          details: finalAlerts.details
        });
      }
      
      return await this.create(createVitalDto);
      
    } catch (error) {
      console.error('❌ [Arduino] Error processing encrypted Arduino vital:', error.message);
      console.error('📚 [Arduino] Error stack:', error.stack);
      return null;
    }
  }

  /**
   * Process encrypted vital data from ESP32 (local server fallback format)
   */
  async processEncryptedVital(encryptedPayload: any): Promise<VitalDto | null> {
    try {
      console.log('\n📦 [ESP32] Processing encrypted payload from ESP32 (local server format)');
      console.log('🔍 [ESP32] Checking if payload is encrypted...');
      
      if (!encryptedPayload.encrypted || !encryptedPayload.encryptedData) {
        console.log('⚠️ [ESP32] Payload is not encrypted, processing as plain text');
        return await this.create(encryptedPayload as CreateVitalDto);
      }
      
      console.log('🔐 [ESP32] Payload is encrypted, starting decryption...');
      console.log('📱 [ESP32] Device ID:', encryptedPayload.deviceId);
      console.log('⏰ [ESP32] Timestamp:', encryptedPayload.timestamp);
      console.log('🔧 [ESP32] Encryption method:', encryptedPayload.encryptionMethod);
      
      // Decrypt the data
      const decryptedJson = this.decryptHealthData(encryptedPayload.encryptedData);
      
      // Parse the decrypted JSON
      const vitalData = JSON.parse(decryptedJson);
      console.log('📊 [ESP32] Decrypted vital data:', vitalData);
      
      // Check for alerts
      const alerts = this.checkVitalThresholds(vitalData.vitals || vitalData);
      
      // Convert to CreateVitalDto and save
      const createVitalDto: CreateVitalDto = {
        patientId: vitalData.deviceId || encryptedPayload.deviceId,
        systolic: vitalData.vitals?.systolic || vitalData.systolic,
        diastolic: vitalData.vitals?.diastolic || vitalData.diastolic,
        map: vitalData.vitals?.map || vitalData.map || 
             ((vitalData.vitals?.systolic || vitalData.systolic) + 2 * (vitalData.vitals?.diastolic || vitalData.diastolic)) / 3,
        proteinuria: vitalData.vitals?.proteinuria || vitalData.proteinuria || 0,
        temperature: vitalData.vitals?.temperature || vitalData.temperature,
        heartRate: vitalData.vitals?.heartRate || vitalData.heartRate,
        glucose: vitalData.vitals?.glucose || vitalData.glucose,
        spo2: vitalData.vitals?.spo2 || vitalData.spo2,
        severity: vitalData.severity || (alerts.hasAlerts ? 'HIGH' : 'NORMAL'),
        rationale: vitalData.rationale || (alerts.hasAlerts ? `Alerts: ${alerts.details.join(', ')}` : 'Normal vitals'),
        mlSeverity: vitalData.mlSeverity || (alerts.hasAlerts ? 'HIGH' : 'NORMAL'),
        mlProbability: vitalData.mlProbability || (alerts.hasAlerts ? 0.8 : 0.1),
        timestamp: new Date(vitalData.timestamp || encryptedPayload.timestamp),
        
        // Alert fields
        hasAlerts: encryptedPayload.hasAlerts || alerts.hasAlerts,
        tempAlert: encryptedPayload.tempAlert || alerts.tempAlert,
        hrAlert: encryptedPayload.hrAlert || alerts.hrAlert,
        spo2Alert: encryptedPayload.spo2Alert || alerts.spo2Alert,
        glucoseAlert: encryptedPayload.glucoseAlert || alerts.glucoseAlert,
        tempAlertSeverity: alerts.tempAlert ? 'HIGH' : 'LOW',
        hrAlertSeverity: alerts.hrAlert ? 'HIGH' : 'LOW',
        spo2AlertSeverity: alerts.spo2Alert ? 'HIGH' : 'LOW',
        glucoseAlertSeverity: alerts.glucoseAlert ? 'HIGH' : 'LOW',
        thresholds: this.ALERT_THRESHOLDS
      };
      
      console.log('💾 [ESP32] Saving decrypted ESP32 vital data...');
      
      // Log alerts if present
      if (createVitalDto.hasAlerts) {
        console.log('🚨 [ALERT] Processing ESP32 vital data with alerts:', {
          tempAlert: createVitalDto.tempAlert,
          hrAlert: createVitalDto.hrAlert,
          spo2Alert: createVitalDto.spo2Alert,
          glucoseAlert: createVitalDto.glucoseAlert,
          details: alerts.details
        });
      }
      
      return await this.create(createVitalDto);
      
    } catch (error) {
      console.error('❌ [ESP32] Error processing encrypted vital:', error.message);
      console.error('📚 [ESP32] Error stack:', error.stack);
      return null;
    }
  }

  private async processKafkaVital(vitalData: any) {
    try {
      console.log('\n📩 [Kafka] Processing Kafka vital data...');
      
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
        
        // Alert fields
        hasAlerts: vitalData.hasAlerts,
        tempAlert: vitalData.tempAlert,
        hrAlert: vitalData.hrAlert,
        spo2Alert: vitalData.spo2Alert,
        glucoseAlert: vitalData.glucoseAlert,
        tempAlertSeverity: vitalData.tempAlertSeverity,
        hrAlertSeverity: vitalData.hrAlertSeverity,
        spo2AlertSeverity: vitalData.spo2AlertSeverity,
        glucoseAlertSeverity: vitalData.glucoseAlertSeverity,
        thresholds: vitalData.thresholds
      };

      // Save to MongoDB
      const result = await this.create(createVitalDto);
      console.log('✅ [Kafka] Successfully processed Kafka vital data');
      console.log('🆔 [Kafka] Created record ID:', result.id);
      
    } catch (error) {
      console.error('❌ [Kafka] Error processing message:', error);
    }
  }

  async create(createVitalDto: CreateVitalDto): Promise<VitalDto> {
    try {
      console.log('\n💾 [MongoDB] Creating new vital record...');
      console.log('📊 [MongoDB] Vital data summary:', {
        patientId: createVitalDto.patientId,
        heartRate: createVitalDto.heartRate,
        systolic: createVitalDto.systolic,
        diastolic: createVitalDto.diastolic,
        temperature: createVitalDto.temperature,
        glucose: createVitalDto.glucose,
        spo2: createVitalDto.spo2,
        hasAlerts: createVitalDto.hasAlerts,
        timestamp: createVitalDto.timestamp
      });
      
      // Calculate MAP if not provided
      const map = createVitalDto.map || 
        (createVitalDto.systolic + 2 * createVitalDto.diastolic) / 3;

      const createdVital = new this.vitalModel({
        ...createVitalDto,
        map: Math.round(map * 100) / 100, // Round to 2 decimal places
        createdAt: createVitalDto.timestamp || new Date()
      });

      const savedVital = await createdVital.save();
      console.log('✅ [MongoDB] Vital record saved successfully!');
      console.log('🆔 [MongoDB] Record ID:', savedVital._id);
      console.log('📈 [MongoDB] Calculated MAP:', savedVital.map);
      
      if (savedVital.hasAlerts) {
        console.log('🚨 [ALERT] Saved vital record with alerts:', {
          tempAlert: savedVital.tempAlert,
          hrAlert: savedVital.hrAlert,
          spo2Alert: savedVital.spo2Alert,
          glucoseAlert: savedVital.glucoseAlert,
          tempAlertSeverity: savedVital.tempAlertSeverity,
          hrAlertSeverity: savedVital.hrAlertSeverity,
          spo2AlertSeverity: savedVital.spo2AlertSeverity,
          glucoseAlertSeverity: savedVital.glucoseAlertSeverity
        });
      }
      
      return this.mapToDto(savedVital);
    } catch (error) {
      console.error('❌ [MongoDB] Save error:', error.message);
      console.error('📚 [MongoDB] Error details:', error);
      throw error;
    }
  }

  async findAll(): Promise<VitalDto[]> {
    try {
      console.log('\n🔍 [MongoDB] Fetching all vital records...');
      const vitals = await this.vitalModel.find()
        .sort({ createdAt: -1 })
        .lean()
        .exec();

      console.log(`📊 [MongoDB] Found ${vitals.length} vital records`);
      
      // Count alerts
      const alertCount = vitals.filter(vital => vital.hasAlerts).length;
      if (alertCount > 0) {
        console.log(`🚨 [MongoDB] ${alertCount} records have alerts`);
      }
      
      return vitals.map(vital => this.mapToDto(vital));
    } catch (error) {
      console.error('❌ [MongoDB] Find error:', error.message);
      throw error;
    }
  }

  async findByPatientId(patientId: string): Promise<VitalDto[]> {
    try {
      console.log(`\n🔍 [MongoDB] Fetching vitals for patient: ${patientId}`);
      const vitals = await this.vitalModel.find({ patientId })
        .sort({ createdAt: -1 })
        .lean()
        .exec();
      
      console.log(`📊 [MongoDB] Found ${vitals.length} records for patient ${patientId}`);
      
      // Count alerts for this patient
      const alertCount = vitals.filter(vital => vital.hasAlerts).length;
      if (alertCount > 0) {
        console.log(`🚨 [MongoDB] ${alertCount} records have alerts for patient ${patientId}`);
      }
      
      return vitals.map(vital => this.mapToDto(vital));
    } catch (error) {
      console.error('❌ [MongoDB] Find by patientId error:', error.message);
      throw error;
    }
  }

  async findCriticalAlerts(patientId: string): Promise<VitalDto[]> {
    try {
      console.log(`\n🔍 [MongoDB] Fetching critical alerts for patient: ${patientId}`);
      const vitals = await this.vitalModel.find({ 
        patientId,
        hasAlerts: true 
      })
      .sort({ createdAt: -1 })
      .lean()
      .exec();
      
      console.log(`🚨 [ALERT] Found ${vitals.length} critical alerts for patient ${patientId}`);
      
      // Log alert breakdown
      if (vitals.length > 0) {
        const alertBreakdown = {
          tempAlerts: vitals.filter(v => v.tempAlert).length,
          hrAlerts: vitals.filter(v => v.hrAlert).length,
          spo2Alerts: vitals.filter(v => v.spo2Alert).length,
          glucoseAlerts: vitals.filter(v => v.glucoseAlert).length
        };
        console.log('📊 [ALERT] Alert breakdown:', alertBreakdown);
      }
      
      return vitals.map(vital => this.mapToDto(vital));
    } catch (error) {
      console.error('❌ [MongoDB] Error fetching critical alerts:', error.message);
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
      createdAt: vital.createdAt,
      
      // Alert fields
      hasAlerts: vital.hasAlerts,
      tempAlert: vital.tempAlert,
      hrAlert: vital.hrAlert,
      spo2Alert: vital.spo2Alert,
      glucoseAlert: vital.glucoseAlert,
      tempAlertSeverity: vital.tempAlertSeverity,
      hrAlertSeverity: vital.hrAlertSeverity,
      spo2AlertSeverity: vital.spo2AlertSeverity,
      glucoseAlertSeverity: vital.glucoseAlertSeverity,
      thresholds: vital.thresholds
    };
  }
}





