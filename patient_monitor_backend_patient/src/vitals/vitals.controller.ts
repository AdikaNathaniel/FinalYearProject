// import { 
//   Controller, 
//   Get, 
//   Post, 
//   Body, 
//   Param, 
//   UseInterceptors, 
//   ClassSerializerInterceptor,
//   HttpException,
//   HttpStatus 
// } from '@nestjs/common';
// import { VitalsService } from './vitals.service';
// import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
// import { VitalDto } from 'src/users/dto/vital.dto';

// interface EncryptedPayload {
//   encryptedData: string;
//   encrypted: boolean;
// }

// @UseInterceptors(ClassSerializerInterceptor)
// @Controller('vitals')
// export class VitalsController {
//   constructor(private readonly vitalsService: VitalsService) {}

//   @Post()
//   async create(@Body() body: any): Promise<VitalDto> {
//     try {
//       console.log('\n🌐 [HTTP] POST /vitals - New request received');
//       console.log('📦 [HTTP] Request body type:', typeof body);
//       console.log('🔍 [HTTP] Request body keys:', Object.keys(body));
      
//       // Check if the payload is encrypted
//       if (body.encrypted && body.encryptedData) {
//         console.log('🔐 [HTTP] Detected encrypted payload from ESP32');
//         console.log('📏 [HTTP] Encrypted data length:', body.encryptedData.length);
        
//         const result = await this.vitalsService.processEncryptedVital(body as EncryptedPayload);
        
//         if (!result) {
//           console.error('❌ [HTTP] Failed to process encrypted vital data');
//           throw new HttpException('Failed to decrypt and process vital data', HttpStatus.BAD_REQUEST);
//         }
        
//         console.log('✅ [HTTP] Successfully processed encrypted vital data');
//         console.log('🆔 [HTTP] Created record ID:', result.id);
//         return result;
        
//       } else {
//         console.log('📝 [HTTP] Processing unencrypted payload (legacy/direct API call)');
//         const createVitalDto = body as CreateVitalDto;
//         console.log('👤 [HTTP] Patient ID:', createVitalDto.patientId);
        
//         const result = await this.vitalsService.create(createVitalDto);
//         console.log('✅ [HTTP] Successfully processed unencrypted vital data');
//         console.log('🆔 [HTTP] Created record ID:', result.id);
//         return result;
//       }
      
//     } catch (error) {
//       console.error('❌ [HTTP] Error in POST /vitals:', error.message);
      
//       if (error instanceof HttpException) {
//         throw error;
//       }
      
//       throw new HttpException(
//         'Internal server error while processing vital data', 
//         HttpStatus.INTERNAL_SERVER_ERROR
//       );
//     }
//   }

//   @Get()
//   async findAll(): Promise<VitalDto[]> {
//     try {
//       console.log('\n🌐 [HTTP] GET /vitals - Fetch all vitals requested');
//       const vitals = await this.vitalsService.findAll();
//       console.log(`✅ [HTTP] Returning ${vitals.length} vital records`);
//       return vitals;
//     } catch (error) {
//       console.error('❌ [HTTP] Error in GET /vitals:', error.message);
//       throw new HttpException(
//         'Failed to fetch vital records', 
//         HttpStatus.INTERNAL_SERVER_ERROR
//       );
//     }
//   }

//   @Get(':patientId')
//   async findByPatientId(@Param('patientId') patientId: string): Promise<VitalDto[]> {
//     try {
//       console.log(`\n🌐 [HTTP] GET /vitals/${patientId} - Fetch patient vitals requested`);
      
//       if (!patientId || patientId.trim().length === 0) {
//         console.error('❌ [HTTP] Invalid patient ID provided');
//         throw new HttpException('Patient ID is required', HttpStatus.BAD_REQUEST);
//       }
      
//       const vitals = await this.vitalsService.findByPatientId(patientId);
//       console.log(`✅ [HTTP] Returning ${vitals.length} vital records for patient ${patientId}`);
//       return vitals;
//     } catch (error) {
//       console.error(`❌ [HTTP] Error in GET /vitals/${patientId}:`, error.message);
      
//       if (error instanceof HttpException) {
//         throw error;
//       }
      
//       throw new HttpException(
//         'Failed to fetch patient vital records', 
//         HttpStatus.INTERNAL_SERVER_ERROR
//       );
//     }
//   }

//   // Health check endpoint for testing AES setup
//   @Get('health/aes-test')
//   async aesHealthCheck(): Promise<{ status: string; message: string; timestamp: string }> {
//     console.log('\n🏥 [HTTP] GET /vitals/health/aes-test - AES health check requested');
//     return {
//       status: 'ok',
//       message: 'VitalsController with AES decryption is ready to receive encrypted data from ESP32',
//       timestamp: new Date().toISOString()
//     };
//   }
// }





// import { 
//   Controller, 
//   Get, 
//   Post, 
//   Body, 
//   Param, 
//   UseInterceptors, 
//   ClassSerializerInterceptor,
//   HttpException,
//   HttpStatus 
// } from '@nestjs/common';
// import { VitalsService } from './vitals.service';
// import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
// import { VitalDto } from 'src/users/dto/vital.dto';

// interface EncryptedPayload {
//   encryptedData: string;
//   encrypted: boolean;
//   hasAlerts?: boolean;
//   tempAlert?: boolean;
//   hrAlert?: boolean;
//   spo2Alert?: boolean;
//   glucoseAlert?: boolean;
// }

// @UseInterceptors(ClassSerializerInterceptor)
// @Controller('vitals')
// export class VitalsController {
//   constructor(private readonly vitalsService: VitalsService) {}

//   @Post()
//   async create(@Body() body: any): Promise<VitalDto> {
//     try {
//       console.log('\n🌐 [HTTP] POST /vitals - New request received');
//       console.log('📦 [HTTP] Request body type:', typeof body);
//       console.log('🔍 [HTTP] Request body keys:', Object.keys(body));
      
//       // Check if the payload is encrypted
//       if (body.encrypted && body.encryptedData) {
//         console.log('🔐 [HTTP] Detected encrypted payload from ESP32');
//         console.log('📏 [HTTP] Encrypted data length:', body.encryptedData.length);
        
//         const result = await this.vitalsService.processEncryptedVital(body as EncryptedPayload);
        
//         if (!result) {
//           console.error('❌ [HTTP] Failed to process encrypted vital data');
//           throw new HttpException('Failed to decrypt and process vital data', HttpStatus.BAD_REQUEST);
//         }
        
//         console.log('✅ [HTTP] Successfully processed encrypted vital data');
//         console.log('🆔 [HTTP] Created record ID:', result.id);
        
//         // Log alerts if present
//         if (result.hasAlerts) {
//           console.log('🚨 [ALERT] Received vital data with alerts:', {
//             tempAlert: result.tempAlert,
//             hrAlert: result.hrAlert,
//             spo2Alert: result.spo2Alert,
//             glucoseAlert: result.glucoseAlert
//           });
//         }
        
//         return result;
        
//       } else {
//         console.log('📝 [HTTP] Processing unencrypted payload (legacy/direct API call)');
//         const createVitalDto = body as CreateVitalDto;
//         console.log('👤 [HTTP] Patient ID:', createVitalDto.patientId);
        
//         const result = await this.vitalsService.create(createVitalDto);
//         console.log('✅ [HTTP] Successfully processed unencrypted vital data');
//         console.log('🆔 [HTTP] Created record ID:', result.id);
        
//         // Log alerts if present
//         if (result.hasAlerts) {
//           console.log('🚨 [ALERT] Received vital data with alerts:', {
//             tempAlert: result.tempAlert,
//             hrAlert: result.hrAlert,
//             spo2Alert: result.spo2Alert,
//             glucoseAlert: result.glucoseAlert
//           });
//         }
        
//         return result;
//       }
      
//     } catch (error) {
//       console.error('❌ [HTTP] Error in POST /vitals:', error.message);
      
//       if (error instanceof HttpException) {
//         throw error;
//       }
      
//       throw new HttpException(
//         'Internal server error while processing vital data', 
//         HttpStatus.INTERNAL_SERVER_ERROR
//       );
//     }
//   }

//   @Get()
//   async findAll(): Promise<VitalDto[]> {
//     try {
//       console.log('\n🌐 [HTTP] GET /vitals - Fetch all vitals requested');
//       const vitals = await this.vitalsService.findAll();
//       console.log(`✅ [HTTP] Returning ${vitals.length} vital records`);
//       return vitals;
//     } catch (error) {
//       console.error('❌ [HTTP] Error in GET /vitals:', error.message);
//       throw new HttpException(
//         'Failed to fetch vital records', 
//         HttpStatus.INTERNAL_SERVER_ERROR
//       );
//     }
//   }

//   @Get(':patientId')
//   async findByPatientId(@Param('patientId') patientId: string): Promise<VitalDto[]> {
//     try {
//       console.log(`\n🌐 [HTTP] GET /vitals/${patientId} - Fetch patient vitals requested`);
      
//       if (!patientId || patientId.trim().length === 0) {
//         console.error('❌ [HTTP] Invalid patient ID provided');
//         throw new HttpException('Patient ID is required', HttpStatus.BAD_REQUEST);
//       }
      
//       const vitals = await this.vitalsService.findByPatientId(patientId);
//       console.log(`✅ [HTTP] Returning ${vitals.length} vital records for patient ${patientId}`);
//       return vitals;
//     } catch (error) {
//       console.error(`❌ [HTTP] Error in GET /vitals/${patientId}:`, error.message);
      
//       if (error instanceof HttpException) {
//         throw error;
//       }
      
//       throw new HttpException(
//         'Failed to fetch patient vital records', 
//         HttpStatus.INTERNAL_SERVER_ERROR
//       );
//     }
//   }

//   // New endpoint to fetch critical alerts
//   @Get('alerts/:patientId')
//   async findCriticalAlerts(@Param('patientId') patientId: string): Promise<VitalDto[]> {
//     try {
//       console.log(`\n🌐 [HTTP] GET /vitals/alerts/${patientId} - Fetch critical alerts requested`);
      
//       if (!patientId || patientId.trim().length === 0) {
//         throw new HttpException('Patient ID is required', HttpStatus.BAD_REQUEST);
//       }
      
//       const criticalVitals = await this.vitalsService.findCriticalAlerts(patientId);
//       console.log(`🚨 [ALERT] Found ${criticalVitals.length} critical alerts for patient ${patientId}`);
//       return criticalVitals;
//     } catch (error) {
//       console.error(`❌ [HTTP] Error in GET /vitals/alerts/${patientId}:`, error.message);
//       throw new HttpException(
//         'Failed to fetch critical alerts', 
//         HttpStatus.INTERNAL_SERVER_ERROR
//       );
//     }
//   }

  // Health check endpoint for testing AES setup
//   @Get('health/aes-test')
//   async aesHealthCheck(): Promise<{ status: string; message: string; timestamp: string }> {
//     console.log('\n🏥 [HTTP] GET /vitals/health/aes-test - AES health check requested');
//     return {
//       status: 'ok',
//       message: 'VitalsController with AES decryption is ready to receive encrypted data from ESP32',
//       timestamp: new Date().toISOString()
//     };
//   }
// }


import { 
  Controller, 
  Get, 
  Post, 
  Body, 
  Param, 
  UseInterceptors, 
  ClassSerializerInterceptor,
  HttpException,
  HttpStatus 
} from '@nestjs/common';
import { VitalsService } from './vitals.service';
import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
import { VitalDto } from 'src/users/dto/vital.dto';

interface EncryptedPayload {
  encryptedData: string;
  encrypted: boolean;
  hasAlerts?: boolean;
  tempAlert?: boolean;
  hrAlert?: boolean;
  spo2Alert?: boolean;
  glucoseAlert?: boolean;
  deviceId?: string;
  timestamp?: string;
  plainTextData?: string; // For debugging/comparison
  encryptionMethod?: string;
  fallbackReason?: string;
  metadata?: any;
  alerts?: any;
}

interface ArduinoEncryptedPayload {
  deviceId: string;
  timestamp: string;
  data: string; // This is the base64 encrypted data from Arduino
  metadata?: {
    encryptionAlgorithm: string;
    encryptionKeySize: number;
    dataFormat: string;
    originalSize: number;
    encryptedSize: number;
    deviceType: string;
    firmwareVersion: string;
  };
  alerts?: {
    hasAlerts: boolean;
    temperature: boolean;
    heartRate: boolean;
    spo2: boolean;
    glucose: boolean;
  };
}

@UseInterceptors(ClassSerializerInterceptor)
@Controller('vitals')
export class VitalsController {
  constructor(private readonly vitalsService: VitalsService) {}

  @Post()
  async create(@Body() body: any): Promise<VitalDto> {
    try {
      console.log('\n🌐 [HTTP] POST /vitals - New request received');
      console.log('📦 [HTTP] Request body type:', typeof body);
      console.log('🔍 [HTTP] Request body keys:', Object.keys(body));
      console.log('📋 [HTTP] Full request body:', JSON.stringify(body, null, 2));
      
      // Check if this is an Arduino payload with encrypted data from Azure fallback
      if (body.deviceId && body.data && body.metadata?.encryptionAlgorithm === 'AES-128-CBC') {
        console.log('🤖 [HTTP] Detected Arduino encrypted payload (Azure Function format)');
        console.log('🔐 [HTTP] Device ID:', body.deviceId);
        console.log('📏 [HTTP] Encrypted data length:', body.data.length);
        console.log('🔧 [HTTP] Encryption method:', body.metadata.encryptionAlgorithm);
        
        const result = await this.vitalsService.processArduinoEncryptedVital(body as ArduinoEncryptedPayload);
        
        if (!result) {
          console.error('❌ [HTTP] Failed to process Arduino encrypted vital data');
          throw new HttpException('Failed to decrypt and process Arduino vital data', HttpStatus.BAD_REQUEST);
        }
        
        console.log('✅ [HTTP] Successfully processed Arduino encrypted vital data');
        console.log('🆔 [HTTP] Created record ID:', result.id);
        
        // Log alerts if present
        if (body.alerts?.hasAlerts) {
          console.log('🚨 [ALERT] Arduino sent vital data with alerts:', {
            tempAlert: body.alerts.temperature,
            hrAlert: body.alerts.heartRate,
            spo2Alert: body.alerts.spo2,
            glucoseAlert: body.alerts.glucose
          });
        }
        
        return result;
      }
      
      // Check if the payload is encrypted (local server fallback format)
      else if (body.encrypted && body.encryptedData) {
        console.log('🔐 [HTTP] Detected encrypted payload from ESP32 (local server format)');
        console.log('📏 [HTTP] Encrypted data length:', body.encryptedData.length);
        console.log('🔧 [HTTP] Encryption method:', body.encryptionMethod || 'AES-128-CBC');
        console.log('📱 [HTTP] Device ID:', body.deviceId);
        
        const result = await this.vitalsService.processEncryptedVital(body as EncryptedPayload);
        
        if (!result) {
          console.error('❌ [HTTP] Failed to process encrypted vital data');
          throw new HttpException('Failed to decrypt and process vital data', HttpStatus.BAD_REQUEST);
        }
        
        console.log('✅ [HTTP] Successfully processed encrypted vital data');
        console.log('🆔 [HTTP] Created record ID:', result.id);
        
        // Log alerts if present
        if (result.hasAlerts) {
          console.log('🚨 [ALERT] Received vital data with alerts:', {
            tempAlert: result.tempAlert,
            hrAlert: result.hrAlert,
            spo2Alert: result.spo2Alert,
            glucoseAlert: result.glucoseAlert
          });
        }
        
        return result;
        
      } else {
        console.log('📝 [HTTP] Processing unencrypted payload (legacy/direct API call)');
        const createVitalDto = body as CreateVitalDto;
        console.log('👤 [HTTP] Patient ID:', createVitalDto.patientId);
        
        const result = await this.vitalsService.create(createVitalDto);
        console.log('✅ [HTTP] Successfully processed unencrypted vital data');
        console.log('🆔 [HTTP] Created record ID:', result.id);
        
        // Log alerts if present
        if (result.hasAlerts) {
          console.log('🚨 [ALERT] Received vital data with alerts:', {
            tempAlert: result.tempAlert,
            hrAlert: result.hrAlert,
            spo2Alert: result.spo2Alert,
            glucoseAlert: result.glucoseAlert
          });
        }
        
        return result;
      }
      
    } catch (error) {
      console.error('❌ [HTTP] Error in POST /vitals:', error.message);
      console.error('📚 [HTTP] Error stack:', error.stack);
      
      if (error instanceof HttpException) {
        throw error;
      }
      
      throw new HttpException(
        'Internal server error while processing vital data', 
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  @Get()
  async findAll(): Promise<VitalDto[]> {
    try {
      console.log('\n🌐 [HTTP] GET /vitals - Fetch all vitals requested');
      const vitals = await this.vitalsService.findAll();
      console.log(`✅ [HTTP] Returning ${vitals.length} vital records`);
      return vitals;
    } catch (error) {
      console.error('❌ [HTTP] Error in GET /vitals:', error.message);
      throw new HttpException(
        'Failed to fetch vital records', 
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  @Get(':patientId')
  async findByPatientId(@Param('patientId') patientId: string): Promise<VitalDto[]> {
    try {
      console.log(`\n🌐 [HTTP] GET /vitals/${patientId} - Fetch patient vitals requested`);
      
      if (!patientId || patientId.trim().length === 0) {
        console.error('❌ [HTTP] Invalid patient ID provided');
        throw new HttpException('Patient ID is required', HttpStatus.BAD_REQUEST);
      }
      
      const vitals = await this.vitalsService.findByPatientId(patientId);
      console.log(`✅ [HTTP] Returning ${vitals.length} vital records for patient ${patientId}`);
      return vitals;
    } catch (error) {
      console.error(`❌ [HTTP] Error in GET /vitals/${patientId}:`, error.message);
      
      if (error instanceof HttpException) {
        throw error;
      }
      
      throw new HttpException(
        'Failed to fetch patient vital records', 
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // New endpoint to fetch critical alerts
  @Get('alerts/:patientId')
  async findCriticalAlerts(@Param('patientId') patientId: string): Promise<VitalDto[]> {
    try {
      console.log(`\n🌐 [HTTP] GET /vitals/alerts/${patientId} - Fetch critical alerts requested`);
      
      if (!patientId || patientId.trim().length === 0) {
        throw new HttpException('Patient ID is required', HttpStatus.BAD_REQUEST);
      }
      
      const criticalVitals = await this.vitalsService.findCriticalAlerts(patientId);
      console.log(`🚨 [ALERT] Found ${criticalVitals.length} critical alerts for patient ${patientId}`);
      return criticalVitals;
    } catch (error) {
      console.error(`❌ [HTTP] Error in GET /vitals/alerts/${patientId}:`, error.message);
      throw new HttpException(
        'Failed to fetch critical alerts', 
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // Health check endpoint for testing AES setup
  @Get('health/aes-test')
  async aesHealthCheck(): Promise<{ status: string; message: string; timestamp: string; config: any }> {
    console.log('\n🏥 [HTTP] GET /vitals/health/aes-test - AES health check requested');
    
    const aesConfig = this.vitalsService.getAESConfiguration();
    
    return {
      status: 'ok',
      message: 'VitalsController with AES-128-CBC decryption is ready to receive encrypted data from ESP32',
      timestamp: new Date().toISOString(),
      config: {
        algorithm: aesConfig.algorithm,
        keyLength: aesConfig.keyLength,
        blockSize: aesConfig.blockSize,
        mode: aesConfig.mode,
        ready: aesConfig.ready
      }
    };
  }

  // Test decryption endpoint
  @Post('test/decrypt')
  async testDecryption(@Body() body: { encryptedData: string }): Promise<any> {
    try {
      console.log('\n🧪 [HTTP] POST /vitals/test/decrypt - Test decryption endpoint');
      console.log('🔐 [HTTP] Testing decryption with provided data');
      
      const result = await this.vitalsService.testDecryptHealthData(body.encryptedData);
      
      if (result.success) {
        console.log('✅ [HTTP] Test decryption successful');
        return {
          success: true,
          message: 'Decryption test successful',
          decryptedData: result.decryptedData,
          parsedData: result.parsedData
        };
      } else {
        console.log('❌ [HTTP] Test decryption failed');
        return {
          success: false,
          message: 'Decryption test failed',
          error: result.error
        };
      }
    } catch (error) {
      console.error('❌ [HTTP] Error in test decryption:', error.message);
      throw new HttpException(
        'Test decryption failed', 
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
}