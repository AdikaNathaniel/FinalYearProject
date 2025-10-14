import { Body, Controller, Get, Patch, Post, Query } from '@nestjs/common';
import { HeltecLiveVitalsService, ChartDataDto } from './heltec-live-vitals.service';
import { CreateHeltecLiveVitalsDto } from 'src/users/dto/create-heltec-live-vitals.dto';
import { NormalizeVitalsPipe } from './normalize-vitals.pipe';

@Controller('heltec-live-vitals')
export class HeltecLiveVitalsController {
  constructor(private readonly heltecVitalsService: HeltecLiveVitalsService) {}

  @Post()
  async create(@Body(NormalizeVitalsPipe) data) {
    return this.heltecVitalsService.createVitals(data);
  }

  @Get('latest')
  getLatest() {
    return this.heltecVitalsService.getLatestVitals();
  }

  @Patch('latest/protein-level')
  updateProteinLevel(@Body('proteinLevel') proteinLevel: number) {
    return this.heltecVitalsService.updateLatestProteinLevel(proteinLevel);
  }

  @Get()
  getAll() {
    return this.heltecVitalsService.getAllVitals();
  }

  // New Chart Endpoints
  @Get('charts/temperature')
  async getTemperatureChart(@Query('days') days: string = '7'): Promise<ChartDataDto> {
    return this.heltecVitalsService.getTemperatureChartData(parseInt(days));
  }

  @Get('charts/blood-pressure')
  async getBloodPressureChart(@Query('days') days: string = '7') {
    return this.heltecVitalsService.getBloodPressureChartData(parseInt(days));
  }

  @Get('charts/heart-rate')
  async getHeartRateChart(@Query('days') days: string = '7') {
    return this.heltecVitalsService.getHeartRateChartData(parseInt(days));
  }

  @Get('charts/oxygen-saturation')
  async getOxygenSaturationChart(@Query('days') days: string = '7') {
    return this.heltecVitalsService.getOxygenSaturationChartData(parseInt(days));
  }

  @Get('charts/blood-glucose')
  async getBloodGlucoseChart(@Query('days') days: string = '7') {
    return this.heltecVitalsService.getBloodGlucoseChartData(parseInt(days));
  }

  @Get('charts/protein-level')
  async getProteinLevelChart(@Query('days') days: string = '30') {
    return this.heltecVitalsService.getProteinLevelChartData(parseInt(days));
  }

  @Get('charts/comprehensive')
  async getComprehensiveCharts(@Query('days') days: string = '7') {
    const daysNum = parseInt(days);
    
    const [
      temperature,
      bloodPressure,
      heartRate,
      oxygenSaturation,
      bloodGlucose,
      proteinLevel
    ] = await Promise.all([
      this.heltecVitalsService.getTemperatureChartData(daysNum),
      this.heltecVitalsService.getBloodPressureChartData(daysNum),
      this.heltecVitalsService.getHeartRateChartData(daysNum),
      this.heltecVitalsService.getOxygenSaturationChartData(daysNum),
      this.heltecVitalsService.getBloodGlucoseChartData(daysNum),
      this.heltecVitalsService.getProteinLevelChartData(30)
    ]);

    return {
      temperature,
      bloodPressure,
      heartRate,
      oxygenSaturation,
      bloodGlucose,
      proteinLevel,
      timestamp: new Date().toISOString(),
    };
  }
}