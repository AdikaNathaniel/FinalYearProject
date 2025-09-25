import { Controller, Get, Query, Post, Body } from '@nestjs/common';
import { HealthAnalyticsService } from './health-analytics.service';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@ApiTags('Health Analytics')
@Controller('health-analytics')
export class HealthAnalyticsController {
  constructor(private readonly healthAnalyticsService: HealthAnalyticsService) {}

  @Get('summary')
  @ApiOperation({ summary: 'Generate patient summary report' })
  async getPatientSummary(@Query('patientName') patientName: string) {
    const response = await this.healthAnalyticsService.generatePatientSummary(patientName);
    return response;  // Return structured response directly
  }

  @Get('query')
  @ApiOperation({ summary: 'Query patient records with natural language' })
  async queryRecords(
    @Query('patientName') patientName: string,
    @Query('question') question: string,
  ) {
    const response = await this.healthAnalyticsService.queryPatientRecords(patientName, question);
    return response;  // Return structured response directly
  }

  @Post('explain-diagnostic')
  @ApiOperation({ summary: 'Explain diagnostic prediction' })
  async explainDiagnostic(
    @Body('patientName') patientName: string,
    @Body('prediction') prediction: string,
  ) {
    const response = await this.healthAnalyticsService.explainDiagnostic(patientName, prediction);
    return response;  // Return structured response directly
  }

  @Post('explain-alert')
  @ApiOperation({ summary: 'Explain medical alert' })
  async explainAlert(
    @Body('patientName') patientName: string,
    @Body('alert') alert: string,
  ) {
    // Keep the original explainAlert function in your service
    const response = await this.healthAnalyticsService.explainAlert(patientName, alert);
    return response;
  }
  
  @Get('patients-with-abnormal-vitals')
  @ApiOperation({ summary: 'Get patients with abnormal vital signs' })
  async getPatientsWithAbnormalVitals() {
    const response = await this.healthAnalyticsService.getPatientsWithAbnormalVitals();
    return response;
  }

  @Post('translate')
  @ApiOperation({ summary: 'Translate medical text' })
  async translateText(
    @Body('text') text: string,
    @Body('targetLanguage') targetLanguage: string,
  ) {
    const response = await this.healthAnalyticsService.translateMedicalText(text, targetLanguage);
    return response;  // Return structured response directly
  }

  @Get('charting-insights')
  @ApiOperation({ summary: 'Generate charting insights and visualizations' })
  async getChartingInsights(@Query('patientName') patientName: string) {
    const response = await this.healthAnalyticsService.generateChartingInsights(patientName);
    return response;  // Return structured response directly
  }

  @Get('patient-vitals')
@ApiOperation({ summary: 'Get all vital signs for a specific patient' })
async getPatientVitals(@Query('patientName') patientName: string) {
  const response = await this.healthAnalyticsService.getPatientVitals(patientName);
  return response;
}

}