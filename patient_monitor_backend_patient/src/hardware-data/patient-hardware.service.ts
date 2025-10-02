import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { HealthData, HealthDataDocument } from 'src/shared/schema/health-data.schema';
import { CreateHealthDataDto } from 'src/users/dto/create-health-data.dto';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';

@Injectable()
export class HealthDataService {
  constructor(
    @InjectModel(HealthData.name)
    private healthDataModel: Model<HealthDataDocument>,
    private readonly httpService: HttpService
  ) {}

  async create(createHealthDataDto: CreateHealthDataDto): Promise<HealthData> {
    const createdData = new this.healthDataModel(createHealthDataDto);
    return createdData.save();
  }

  async findAll(patient?: string, limit: number = 50): Promise<HealthData[]> {
    const filter = patient ? { patient_name: patient } : {};
    return this.healthDataModel
      .find(filter)
      .sort({ createdAt: -1 })
      .limit(limit)
      .exec();
  }

  async findLatest(patient?: string): Promise<HealthData> {
    const filter = patient ? { patient_name: patient } : {};
    return this.healthDataModel
      .findOne(filter)
      .sort({ createdAt: -1 })
      .exec();
  }


  async fetchFromBeeceptorAndSave(): Promise<any> {
  const url = 'https://qtcb9cce19673e3ad0c0f584b9cd.free.beeceptor.com';

  try {
    const response$ = this.httpService.get(url);
    const response = await lastValueFrom(response$);
    const data = response.data;

    // Optional: Validate/transform `data` to match CreateHealthDataDto if needed
    const saved = await this.create(data); // reuses your create method

    return {
      message: 'Fetched and saved health data successfully',
      data: saved,
    };
  } catch (error) {
    console.error('❌ Error fetching or saving data:', error.message);
    throw new Error('Failed to fetch or save data from external source');
  }
}


  async getStats(patient?: string) {
    const filter = patient ? { patient_name: patient } : {};
    
    const totalRecords = await this.healthDataModel.countDocuments(filter);
    
    const riskStats = await this.healthDataModel.aggregate([
      { $match: filter },
      {
        $group: {
          _id: null,
          totalPreeclampsiaRisk: { $sum: { $cond: ['$preeclampsia_risk', 1, 0] } },
          totalAnemiaRisk: { $sum: { $cond: ['$anemia_risk', 1, 0] } },
          totalGdmRisk: { $sum: { $cond: ['$gdm_risk', 1, 0] } },
          avgTemperature: { $avg: '$temperature' },
          avgHeartRate: { $avg: '$heart_rate' },
          avgSystolicBP: { $avg: '$systolic_bp' },
          avgDiastolicBP: { $avg: '$diastolic_bp' },
          avgGlucose: { $avg: '$glucose' },
          avgSpo2: { $avg: '$spo2' },
          avgBmi: { $avg: '$bmi' }
        }
      }
    ]);

    return {
      totalRecords,
      riskPercentages: riskStats[0] ? {
        preeclampsia: ((riskStats[0].totalPreeclampsiaRisk / totalRecords) * 100).toFixed(1),
        anemia: ((riskStats[0].totalAnemiaRisk / totalRecords) * 100).toFixed(1),
        gdm: ((riskStats[0].totalGdmRisk / totalRecords) * 100).toFixed(1)
      } : null,
      averages: riskStats[0] ? {
        temperature: Number(riskStats[0].avgTemperature.toFixed(1)),
        heartRate: Math.round(riskStats[0].avgHeartRate),
        systolicBP: Math.round(riskStats[0].avgSystolicBP),
        diastolicBP: Math.round(riskStats[0].avgDiastolicBP),
        glucose: Number(riskStats[0].avgGlucose.toFixed(1)),
        spo2: Math.round(riskStats[0].avgSpo2),
        bmi: Number(riskStats[0].avgBmi.toFixed(1))
      } : null
    };
  }
}