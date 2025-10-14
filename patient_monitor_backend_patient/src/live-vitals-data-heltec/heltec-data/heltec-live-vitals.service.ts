import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { HeltecLiveVitals } from 'src/shared/schema/heltec-live-vitals.schema';
import { CreateHeltecLiveVitalsDto } from 'src/users/dto/create-heltec-live-vitals.dto';

export interface ChartDataDto {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    borderColor: string;
    backgroundColor: string;
    tension?: number;
  }[];
}

@Injectable()
export class HeltecLiveVitalsService {
  constructor(@InjectModel(HeltecLiveVitals.name) private heltecVitalsModel: Model<HeltecLiveVitals>) {}

  // POST vitals
  async createVitals(dto: CreateHeltecLiveVitalsDto): Promise<HeltecLiveVitals> {
    const newVitals = new this.heltecVitalsModel(dto);
    return newVitals.save();
  }

  // GET latest vitals
  async getLatestVitals(): Promise<HeltecLiveVitals> {
    const vitals = await this.heltecVitalsModel.findOne().sort({ createdAt: -1 }).exec();
    if (!vitals) throw new NotFoundException('No vitals found');
    return vitals;
  }

  async updateLatestProteinLevel(proteinLevel: number) {
    const latest = await this.heltecVitalsModel.findOne().sort({ createdAt: -1 }).exec();
    if (!latest) throw new NotFoundException('No vitals found to update');
    latest.proteinLevel = proteinLevel;
    return latest.save();
  }

  // GET all vitals history
  async getAllVitals(): Promise<HeltecLiveVitals[]> {
    return this.heltecVitalsModel.find().sort({ createdAt: -1 }).exec();
  }

  // Helper method to get data by date range
  private async getDataByDateRange(days: number): Promise<HeltecLiveVitals[]> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    return this.heltecVitalsModel
      .find({
        createdAt: {
          $gte: startDate,
          $lte: endDate,
        },
      })
      .sort({ createdAt: 1 })
      .exec();
  }

  // Helper method to format labels based on time range
  private formatLabels(data: HeltecLiveVitals[], days: number): string[] {
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

  // Chart Data Methods
  async getTemperatureChartData(days: number = 7): Promise<ChartDataDto> {
    const data = await this.getDataByDateRange(days);
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
        {
          label: 'Skin Temperature (°C)',
          data: data.map(item => item.skinTemp),
          borderColor: 'rgb(54, 162, 235)',
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getBloodPressureChartData(days: number = 7): Promise<ChartDataDto> {
    const data = await this.getDataByDateRange(days);
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

  async getHeartRateChartData(days: number = 7): Promise<ChartDataDto> {
    const data = await this.getDataByDateRange(days);
    const labels = this.formatLabels(data, days);

    // Filter out zero values for heart rate
    const filteredData = data.filter(item => item.heartRate > 0);
    const filteredLabels = this.formatLabels(filteredData, days);

    return {
      labels: filteredLabels,
      datasets: [
        {
          label: 'Heart Rate (BPM)',
          data: filteredData.map(item => item.heartRate),
          borderColor: 'rgb(255, 159, 64)',
          backgroundColor: 'rgba(255, 159, 64, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getOxygenSaturationChartData(days: number = 7): Promise<ChartDataDto> {
    const data = await this.getDataByDateRange(days);
    const labels = this.formatLabels(data, days);

    // Filter out zero values for SpO2
    const filteredData = data.filter(item => item.spo2 > 0);
    const filteredLabels = this.formatLabels(filteredData, days);

    return {
      labels: filteredLabels,
      datasets: [
        {
          label: 'Oxygen Saturation (SpO2 %)',
          data: filteredData.map(item => item.spo2),
          borderColor: 'rgb(75, 192, 192)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getBloodGlucoseChartData(days: number = 7): Promise<ChartDataDto> {
    const data = await this.getDataByDateRange(days);
    const labels = this.formatLabels(data, days);

    // Filter out unrealistic glucose values (keep only reasonable human range)
    const filteredData = data.filter(item => item.glucose > 50 && item.glucose < 400);
    const filteredLabels = this.formatLabels(filteredData, days);

    return {
      labels: filteredLabels,
      datasets: [
        {
          label: 'Blood Glucose (mg/dL)',
          data: filteredData.map(item => item.glucose),
          borderColor: 'rgb(153, 102, 255)',
          backgroundColor: 'rgba(153, 102, 255, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }

  async getProteinLevelChartData(days: number = 30): Promise<ChartDataDto> {
    const data = await this.getDataByDateRange(days);
    const labels = this.formatLabels(data, days);

    // Filter out records without protein level
    const filteredData = data.filter(item => item.proteinLevel !== undefined && item.proteinLevel !== null);
    const filteredLabels = this.formatLabels(filteredData, days);

    return {
      labels: filteredLabels,
      datasets: [
        {
          label: 'Protein Level',
          data: filteredData.map(item => item.proteinLevel),
          borderColor: 'rgb(201, 203, 207)',
          backgroundColor: 'rgba(201, 203, 207, 0.2)',
          tension: 0.4,
        },
      ],
    };
  }
}