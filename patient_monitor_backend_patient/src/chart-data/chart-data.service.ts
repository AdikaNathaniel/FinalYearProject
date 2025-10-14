import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ChartData } from 'src/shared/schema/chart-data.schema';
import { ChartDataDto } from 'src/users/dto/chart-data.dto';

@Injectable()
export class ChartDataService {
  constructor(
    @InjectModel(ChartData.name) private chartDataModel: Model<ChartData>,
  ) {}

  async create(createChartDataDto: ChartDataDto): Promise<ChartData> {
    const createdData = new this.chartDataModel(createChartDataDto);
    return createdData.save();
  }

  async findAll(): Promise<ChartData[]> {
    return this.chartDataModel.find().sort({ createdAt: -1 }).exec();
  }

  async findByDateRange(startDate: Date, endDate: Date): Promise<ChartData[]> {
    return this.chartDataModel
      .find({
        createdAt: {
          $gte: startDate,
          $lte: endDate,
        },
      })
      .sort({ createdAt: 1 })
      .exec();
  }

  private formatLabels(data: ChartData[], days: number): string[] {
    if (days <= 1) {
      // For 1 day or less, show time
      return data.map(item =>
        item.createdAt.toLocaleTimeString('en-US', {
          hour: '2-digit',
          minute: '2-digit',
        }),
      );
    } else if (days <= 7) {
      // For up to 7 days, show date and time
      return data.map(item =>
        item.createdAt.toLocaleDateString('en-US', {
          month: 'short',
          day: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
        }),
      );
    } else {
      // For more than 7 days, show date only
      return data.map(item =>
        item.createdAt.toLocaleDateString('en-US', {
          month: 'short',
          day: 'numeric',
        }),
      );
    }
  }

  async getTemperatureTrendChartData(days: number = 7): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Body Temperature (°C)',
          data: data.map(item => item.bodyTemp),
          borderColor: 'rgb(255, 99, 132)',
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getOxygenSaturationChartData(days: number = 7): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Oxygen Saturation (SpO2 %)',
          data: data.map(item => item.spo2),
          borderColor: 'rgb(54, 162, 235)',
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getBloodPressureChartData(days: number = 7): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Systolic BP (mmHg)',
          data: data.map(item => item.systolicBP),
          borderColor: 'rgb(255, 99, 132)',
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
          tension: 0.4,
        },
        {
          label: 'Diastolic BP (mmHg)',
          data: data.map(item => item.diastolicBP),
          borderColor: 'rgb(54, 162, 235)',
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getBloodGlucoseChartData(days: number = 7): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Blood Glucose (mg/dL)',
          data: data.map(item => item.glucose),
          borderColor: 'rgb(153, 102, 255)',
          backgroundColor: 'rgba(153, 102, 255, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getHeartRateChartData(days: number = 7): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Heart Rate (BPM)',
          data: data.map(item => item.heartRate),
          borderColor: 'rgb(255, 159, 64)',
          backgroundColor: 'rgba(255, 159, 64, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getVitalTrendsChartData(days: number = 7): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Glucose (mg/dL)',
          data: data.map(item => item.glucose),
          borderColor: 'rgb(255, 99, 132)',
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
        },
        {
          label: 'Heart Rate (BPM)',
          data: data.map(item => item.heartRate),
          borderColor: 'rgb(54, 162, 235)',
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
        },
        {
          label: 'Systolic BP',
          data: data.map(item => item.systolicBP),
          borderColor: 'rgb(255, 205, 86)',
          backgroundColor: 'rgba(255, 205, 86, 0.2)',
        },
        {
          label: 'Diastolic BP',
          data: data.map(item => item.diastolicBP),
          borderColor: 'rgb(75, 192, 192)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
        },
      ],
    };
  }

  async getTemperatureComparisonChartData(days: number = 7): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Body Temperature (°C)',
          data: data.map(item => item.bodyTemp),
          borderColor: 'rgb(255, 99, 132)',
          backgroundColor: 'rgba(255, 99, 132, 0.5)',
        },
        {
          label: 'Skin Temperature (°C)',
          data: data.map(item => item.skinTemp),
          borderColor: 'rgb(54, 162, 235)',
          backgroundColor: 'rgba(54, 162, 235, 0.5)',
        },
      ],
    };
  }

  async getVitalStatisticsBarChart(): Promise<ChartDataDto> {
    const data = await this.findAll();
    const latestData = data[0]; // Latest reading

    return {
      labels: ['Glucose', 'Systolic BP', 'Diastolic BP', 'Heart Rate', 'SpO2', 'Body Temp'],
      datasets: [
        {
          label: 'Current Readings',
          data: [
            latestData.glucose,
            latestData.systolicBP,
            latestData.diastolicBP,
            latestData.heartRate,
            latestData.spo2,
            latestData.bodyTemp,
          ],
          backgroundColor: 'rgba(255, 99, 132, 0.8)',
          borderColor: 'rgb(255, 99, 132)',
        },
      ],
    };
  }

  async getRiskAssessmentPieChart(): Promise<ChartDataDto> {
    const data = await this.findAll();
    const latestData = data[0];

    // Simple risk assessment based on thresholds
    const risks = {
      highGlucose: latestData.glucose > 180 ? 1 : 0,
      highBP: latestData.systolicBP > 140 || latestData.diastolicBP > 90 ? 1 : 0,
      highHeartRate: latestData.heartRate > 100 ? 1 : 0,
      lowOxygen: latestData.spo2 < 95 ? 1 : 0,
      fever: latestData.bodyTemp > 38 ? 1 : 0,
    };

    const riskCount = Object.values(risks).reduce((a, b) => a + b, 0);
    const normalCount = 5 - riskCount;

    return {
      labels: ['Normal Parameters', 'Abnormal Parameters'],
      datasets: [
        {
          label: 'Risk Assessment',
          data: [normalCount, riskCount],
          backgroundColor: 'rgba(75, 192, 192, 0.8)',
          borderColor: 'rgb(75, 192, 192)',
        },
      ],
    };
  }

  async getMovementAnalysisChart(days: number = 1): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Acceleration X',
          data: data.map(item => item.accelX),
          borderColor: 'rgb(255, 99, 132)',
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
        },
        {
          label: 'Acceleration Y',
          data: data.map(item => item.accelY),
          borderColor: 'rgb(54, 162, 235)',
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
        },
        {
          label: 'Acceleration Z',
          data: data.map(item => item.accelZ),
          borderColor: 'rgb(255, 205, 86)',
          backgroundColor: 'rgba(255, 205, 86, 0.2)',
        },
      ],
    };
  }

  async getProteinLevelTrendChart(days: number = 30): Promise<ChartDataDto> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const data = await this.findByDateRange(startDate, endDate);
    const labels = this.formatLabels(data, days);

    return {
      labels,
      datasets: [
        {
          label: 'Protein Level',
          data: data.map(item => item.proteinLevel),
          borderColor: 'rgb(153, 102, 255)',
          backgroundColor: 'rgba(153, 102, 255, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }
}