// src/dto/dashboard-response.dto.ts
import { ChartDataDto } from 'src/users/dto/chart-data.dto';

export class DashboardResponseDto {
  vitalTrends: ChartDataDto;
  temperatureComparison: ChartDataDto;
  oxygenSaturation: ChartDataDto;
  vitalStatistics: ChartDataDto;
  riskAssessment: ChartDataDto;
  movementAnalysis: ChartDataDto;
  proteinTrend: ChartDataDto;
  timestamp: string;
}