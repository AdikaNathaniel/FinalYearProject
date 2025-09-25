// src/controllers/chart-data.controller.ts
import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { ChartDataService } from './chart-data.service';
import { ChartDataDto } from 'src/users/dto/chart-data.dto';
import { CreateChartDataDto } from 'src/users/dto/create-chart-data.dto';

@Controller('chart-data')
export class ChartDataController {
  constructor(private readonly chartDataService: ChartDataService) {}

  @Post()
  async create(@Body() chartDataDto: ChartDataDto) {
    return this.chartDataService.create(chartDataDto);
  }

  @Get()
  async findAll() {
    return this.chartDataService.findAll();
  }

  @Get('vital-trends')
  async getVitalTrends(
    @Query('days') days: string = '7',
  ): Promise<ChartDataDto> {
    return this.chartDataService.getVitalTrendsChartData(parseInt(days));
  }

  @Get('temperature-comparison')
  async getTemperatureComparison(
    @Query('days') days: string = '7',
  ): Promise<ChartDataDto> {
    return this.chartDataService.getTemperatureComparisonChartData(parseInt(days));
  }

  @Get('oxygen-saturation')
  async getOxygenSaturation(
    @Query('days') days: string = '7',
  ): Promise<ChartDataDto> {
    return this.chartDataService.getOxygenSaturationChartData(parseInt(days));
  }

  @Get('vital-statistics')
  async getVitalStatistics(): Promise<ChartDataDto> {
    return this.chartDataService.getVitalStatisticsBarChart();
  }

  @Get('risk-assessment')
  async getRiskAssessment(): Promise<ChartDataDto> {
    return this.chartDataService.getRiskAssessmentPieChart();
  }

  @Get('movement-analysis')
  async getMovementAnalysis(
    @Query('days') days: string = '1',
  ): Promise<ChartDataDto> {
    return this.chartDataService.getMovementAnalysisChart(parseInt(days));
  }

  @Get('protein-trend')
  async getProteinLevelTrend(
    @Query('days') days: string = '30',
  ): Promise<ChartDataDto> {
    return this.chartDataService.getProteinLevelTrendChart(parseInt(days));
  }

  @Get('comprehensive-dashboard')
  async getComprehensiveDashboard(@Query('days') days: string = '7') {
    const daysNum = parseInt(days);
    
    const [
      vitalTrends,
      temperatureComparison,
      oxygenSaturation,
      vitalStatistics,
      riskAssessment,
      movementAnalysis,
      proteinTrend,
    ] = await Promise.all([
      this.chartDataService.getVitalTrendsChartData(daysNum),
      this.chartDataService.getTemperatureComparisonChartData(daysNum),
      this.chartDataService.getOxygenSaturationChartData(daysNum),
      this.chartDataService.getVitalStatisticsBarChart(),
      this.chartDataService.getRiskAssessmentPieChart(),
      this.chartDataService.getMovementAnalysisChart(1),
      this.chartDataService.getProteinLevelTrendChart(30),
    ]);

    return {
      vitalTrends,
      temperatureComparison,
      oxygenSaturation,
      vitalStatistics,
      riskAssessment,
      movementAnalysis,
      proteinTrend,
      timestamp: new Date().toISOString(),
    };
  }
}