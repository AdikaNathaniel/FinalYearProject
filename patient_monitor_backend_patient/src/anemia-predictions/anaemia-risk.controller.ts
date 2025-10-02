import { 
  Controller, 
  Get, 
  Post, 
  Delete,
  Patch,
  Body, 
  Param, 
  Query,
  HttpCode,
  HttpStatus,
  ValidationPipe,
  ParseUUIDPipe
} from '@nestjs/common';
import { AnaemiaRiskService } from './anaemia-risk.service';
import { PredictRiskDto } from 'src/users/dto/predict-risk.dto';
import { RiskResultDto } from 'src/users/dto/risk-result.dto';
import { RiskAssessment } from 'src/shared/schema/risk-assessment.schema';
import { 
  ApiTags, 
  ApiOperation, 
  ApiResponse, 
  ApiParam, 
  ApiQuery,
  ApiBadRequestResponse,
  ApiNotFoundResponse 
} from '@nestjs/swagger';

@ApiTags('Anaemia Risk Assessment')
@Controller('anaemia-risk')
export class AnaemiaRiskController {
  constructor(private readonly anaemiaRiskService: AnaemiaRiskService) {}

  @Post('predict')
  @ApiOperation({ summary: 'Predict anaemia risk for a patient' })
  @ApiResponse({ 
    status: 201, 
    description: 'Risk assessment completed successfully',
    type: RiskResultDto 
  })
  @ApiBadRequestResponse({ description: 'Invalid input data or patient ID' })
  @HttpCode(HttpStatus.CREATED)
  async predictRisk(
    @Body(new ValidationPipe()) predictRiskDto: PredictRiskDto
  ): Promise<RiskResultDto> {
    return this.anaemiaRiskService.predictRisk(predictRiskDto);
  }

  @Get('statistics')
  @ApiOperation({ summary: 'Get anaemia risk statistics with interpretations' })
  @ApiResponse({ 
    status: 200, 
    description: 'Statistics with interpretations and detailed analysis'
  })
  async getAssessmentStatistics(
    @Query('patientId') patientId?: string
  ): Promise<{
    statistics: any;
    interpretations: string[];
    summary: {
      totalAssessments: number;
      riskDistribution: {
        low: number;
        mild: number;
        moderate: number;
        high: number;
      };
      averageRisk: number;
      riskSpread: {
        standardDeviation: number;
        variance: number;
        range: {
          min: number;
          max: number;
        };
      };
      timeline: {
        earliest: Date;
        latest: Date;
      };
    };
  }> {
    const result = await this.anaemiaRiskService.getAssessmentStatistics(patientId);
    
    // If your service returns { stats, interpretations }, restructure it
    if (result && typeof result === 'object' && 'stats' in result && 'interpretations' in result) {
      const { stats, interpretations } = result;
      
      return {
        statistics: stats,
        interpretations: interpretations || [],
        summary: {
          totalAssessments: stats.totalAssessments || 0,
          riskDistribution: {
            low: stats.lowRiskCount || 0,
            mild: stats.mildRiskCount || 0,
            moderate: stats.moderateRiskCount || 0,
            high: stats.highRiskCount || 0
          },
          averageRisk: stats.averageRiskScore || 0,
          riskSpread: {
            standardDeviation: stats.riskStdDev || 0,
            variance: stats.riskVariance || 0,
            range: {
              min: stats.minRisk || 0,
              max: stats.maxRisk || 0
            }
          },
          timeline: {
            earliest: stats.earliestAssessment,
            latest: stats.latestAssessment
          }
        }
      };
    }
    
    // Fallback if service returns unexpected format
    return {
      statistics: result,
      interpretations: [],
      summary: {
        totalAssessments: 0,
        riskDistribution: { low: 0, mild: 0, moderate: 0, high: 0 },
        averageRisk: 0,
        riskSpread: { standardDeviation: 0, variance: 0, range: { min: 0, max: 0 } },
        timeline: { earliest: null, latest: null }
      }
    };
  }

  @Get('statistics/raw')
  @ApiOperation({ summary: 'Get raw statistics data (for debugging)' })
  @ApiResponse({ 
    status: 200, 
    description: 'Raw statistics data exactly as returned by service'
  })
  async getRawStatistics(
    @Query('patientId') patientId?: string
  ): Promise<any> {
    // This endpoint returns the exact service response for debugging
    return this.anaemiaRiskService.getAssessmentStatistics(patientId);
  }

  @Get('assessments')
  @ApiOperation({ summary: 'Get all risk assessments' })
  @ApiResponse({ 
    status: 200, 
    description: 'List of all risk assessments',
    type: [RiskAssessment] 
  })
  @ApiQuery({ 
    name: 'patientId', 
    required: false, 
    description: 'Filter by patient ID' 
  })
  async getRiskAssessments(
    @Query('patientId') patientId?: string
  ): Promise<RiskAssessment[]> {
    if (patientId) {
      return this.anaemiaRiskService.getRiskAssessmentsByPatientId(patientId);
    }
    return this.anaemiaRiskService.getRiskAssessments();
  }

  @Get('assessments/patient/:patientId')
  @ApiOperation({ summary: 'Get all risk assessments for a specific patient' })
  @ApiParam({ name: 'patientId', description: 'Patient ID' })
  @ApiResponse({ 
    status: 200, 
    description: 'List of risk assessments for the patient',
    type: [RiskAssessment] 
  })
  @ApiBadRequestResponse({ description: 'Invalid patient ID format' })
  async getPatientAssessments(
    @Param('patientId') patientId: string
  ): Promise<RiskAssessment[]> {
    return this.anaemiaRiskService.getRiskAssessmentsByPatientId(patientId);
  }

  @Get('assessments/patient/:patientId/latest')
  @ApiOperation({ summary: 'Get the latest risk assessment for a specific patient' })
  @ApiParam({ name: 'patientId', description: 'Patient ID' })
  @ApiResponse({ 
    status: 200, 
    description: 'Latest risk assessment for the patient',
    type: RiskAssessment 
  })
  @ApiNotFoundResponse({ description: 'No assessments found for this patient' })
  @ApiBadRequestResponse({ description: 'Invalid patient ID format' })
  async getLatestPatientAssessment(
    @Param('patientId') patientId: string
  ): Promise<RiskAssessment | null> {
    return this.anaemiaRiskService.getLatestRiskAssessmentByPatientId(patientId);
  }

  @Get('assessments/:assessmentId')
  @ApiOperation({ summary: 'Get a specific risk assessment by ID' })
  @ApiParam({ name: 'assessmentId', description: 'Assessment ID' })
  @ApiResponse({ 
    status: 200, 
    description: 'Risk assessment details',
    type: RiskAssessment 
  })
  @ApiNotFoundResponse({ description: 'Assessment not found' })
  @ApiBadRequestResponse({ description: 'Invalid assessment ID format' })
  async getRiskAssessmentById(
    @Param('assessmentId') assessmentId: string
  ): Promise<RiskAssessment> {
    return this.anaemiaRiskService.getRiskAssessmentById(assessmentId);
  }

  @Delete('assessments/:assessmentId')
  @ApiOperation({ summary: 'Delete a specific risk assessment' })
  @ApiParam({ name: 'assessmentId', description: 'Assessment ID' })
  @ApiResponse({ 
    status: 204, 
    description: 'Assessment deleted successfully' 
  })
  @ApiNotFoundResponse({ description: 'Assessment not found' })
  @ApiBadRequestResponse({ description: 'Invalid assessment ID format' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteRiskAssessment(
    @Param('assessmentId') assessmentId: string
  ): Promise<void> {
    return this.anaemiaRiskService.deleteRiskAssessment(assessmentId);
  }

  @Patch('assessments/:assessmentId')
  @ApiOperation({ summary: 'Update a specific risk assessment' })
  @ApiParam({ name: 'assessmentId', description: 'Assessment ID' })
  @ApiResponse({ 
    status: 200, 
    description: 'Assessment updated successfully',
    type: RiskAssessment 
  })
  @ApiNotFoundResponse({ description: 'Assessment not found' })
  @ApiBadRequestResponse({ description: 'Invalid assessment ID format or data' })
  async updateRiskAssessment(
    @Param('assessmentId') assessmentId: string,
    @Body(new ValidationPipe()) updateData: Partial<RiskAssessment>
  ): Promise<RiskAssessment> {
    return this.anaemiaRiskService.updateRiskAssessment(assessmentId, updateData);
  }

  @Get('statistics/patient/:patientId')
  @ApiOperation({ summary: 'Get assessment statistics for a specific patient' })
  @ApiParam({ name: 'patientId', description: 'Patient ID' })
  @ApiResponse({ 
    status: 200, 
    description: 'Patient-specific assessment statistics with interpretations' 
  })
  @ApiBadRequestResponse({ description: 'Invalid patient ID format' })
  async getPatientStatistics(
    @Param('patientId') patientId: string
  ): Promise<{
    patientId: string;
    statistics: any;
    interpretations: string[];
    patientSpecificInsights: string[];
  }> {
    const result = await this.anaemiaRiskService.getAssessmentStatistics(patientId);
    
    // Enhanced patient-specific response
    const response = {
      patientId,
      statistics: result.stats || result,
      interpretations: result.interpretations || [],
      patientSpecificInsights: []
    };

    // Add patient-specific insights
    if (result.stats || result) {
      const stats = result.stats || result;
      const insights = [];
      
      if (stats.totalAssessments === 1) {
        insights.push("This is the patient's first risk assessment. Future assessments will help track trends.");
      } else if (stats.totalAssessments > 1) {
        insights.push(`This patient has ${stats.totalAssessments} assessments on record, allowing for trend analysis.`);
      }
      
      if (stats.averageRiskScore > 70) {
        insights.push("Patient consistently shows high risk scores - immediate intervention may be needed.");
      } else if (stats.averageRiskScore < 45) {
        insights.push("Patient generally shows low risk scores - continue monitoring preventive measures.");
      }
      
      response.patientSpecificInsights = insights;
    }
    
    return response;
  }

  // Additional utility endpoints

  @Get('health')
  @ApiOperation({ summary: 'Health check endpoint' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  async healthCheck(): Promise<{ status: string; timestamp: string }> {
    return {
      status: 'OK',
      timestamp: new Date().toISOString()
    };
  }

  @Get('assessments/count')
  @ApiOperation({ summary: 'Get total count of assessments' })
  @ApiQuery({ 
    name: 'patientId', 
    required: false, 
    description: 'Count assessments for a specific patient' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Assessment count' 
  })
  async getAssessmentCount(
    @Query('patientId') patientId?: string
  ): Promise<{ count: number; patientId?: string }> {
    const assessments = patientId 
      ? await this.anaemiaRiskService.getRiskAssessmentsByPatientId(patientId)
      : await this.anaemiaRiskService.getRiskAssessments();
    
    const response: { count: number; patientId?: string } = { count: assessments.length };
    if (patientId) {
      response.patientId = patientId;
    }
    
    return response;
  }

  @Get('statistics/summary')
  @ApiOperation({ summary: 'Get quick statistics summary' })
  @ApiResponse({ 
    status: 200, 
    description: 'Quick overview of all assessments' 
  })
  async getStatisticsSummary(): Promise<{
    overview: {
      totalAssessments: number;
      highRiskPatients: number;
      averageRiskScore: number;
      lastAssessmentDate: Date | null;
    };
    quickInsights: string[];
  }> {
    const result = await this.anaemiaRiskService.getAssessmentStatistics();
    const stats = result.stats || result;
    
    const overview = {
      totalAssessments: stats.totalAssessments || 0,
      highRiskPatients: stats.highRiskCount || 0,
      averageRiskScore: stats.averageRiskScore || 0,
      lastAssessmentDate: stats.latestAssessment || null
    };
    
    const quickInsights = [];
    
    if (overview.highRiskPatients > 0) {
      quickInsights.push(`${overview.highRiskPatients} patients are currently in the high-risk category.`);
    }
    
    if (overview.totalAssessments > 0) {
      const highRiskPercentage = ((overview.highRiskPatients / overview.totalAssessments) * 100).toFixed(1);
      quickInsights.push(`${highRiskPercentage}% of all assessments indicate high risk.`);
    }
    
    if (overview.averageRiskScore > 60) {
      quickInsights.push("Overall risk levels are concerning - consider population-wide interventions.");
    }
    
    return { overview, quickInsights };
  }
}