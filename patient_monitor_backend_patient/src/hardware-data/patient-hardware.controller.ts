import { Controller, Get, Post, Body, Query } from '@nestjs/common';
import { HealthDataService } from './patient-hardware.service';
import { CreateHealthDataDto } from 'src/users/dto/create-health-data.dto';

@Controller('health-data')
export class HealthDataController {
  constructor(private readonly healthDataService: HealthDataService) {}

  @Post()
  async create(@Body() createHealthDataDto: CreateHealthDataDto) {
    console.log('📊 Received health data:', createHealthDataDto);
    
    const savedData = await this.healthDataService.create(createHealthDataDto);
    
    console.log('✅ Data saved to MongoDB with ID:', (savedData as any)._id);
    
    return {
      message: 'Health data received and saved successfully',
      data: savedData,
      timestamp: new Date().toISOString()
    };
  }

  @Get()
  async findAll(
    @Query('patient') patient?: string,
    @Query('limit') limit: number = 50,
  ) {
    return this.healthDataService.findAll(patient, limit);
  }

  @Get('latest')
  async findLatest(@Query('patient') patient?: string) {
    return this.healthDataService.findLatest(patient);
  }

  @Get('stats')
  async getStats(@Query('patient') patient?: string) {
    return this.healthDataService.getStats(patient);
  }



  @Get('fetch-save')
async fetchAndSaveFromExternal() {
  const result = await this.healthDataService.fetchFromBeeceptorAndSave();
  return {
    ...result,
    timestamp: new Date().toISOString(),
  };
}

}