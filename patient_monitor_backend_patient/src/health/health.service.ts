import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateHealthDto } from 'src/users/dto/create-health.dto';
import { UpdateHealthDto } from 'src/users/dto/update-health.dto';
import { Health, HealthDocument } from 'src/shared/schema/health.schema';

@Injectable()
export class HealthService {
  constructor(@InjectModel(Health.name) private healthModel: Model<HealthDocument>) {}

  async create(
    createHealthDto: CreateHealthDto,
  ): Promise<{ success: boolean; message: string; result: Health }> {
    const healthData = new this.healthModel(createHealthDto);
    const savedHealthData = await healthData.save();

    return {
      success: true,
      message: 'Health data created successfully',
      result: savedHealthData,
    };
  }

  async findAll(): Promise<{
    timestamps: string;
    statusCode: number;
    path: string;
    error: null;
    result: any[];
  }> {
    const timestamp = new Date().toISOString();
    const path = '/api/v1/health'; // Adjust this if your actual path differs

    try {
      // Fetch all health records from the database
      const healthRecords = await this.healthModel.find().exec();

      // Structure the response to include health details
      const healthList = healthRecords.map((record) => ({
        age: record.age,
        parity: record.parity,
        gravida: record.gravida,
        gestationalAge: record.gestationalAge,
        hasDiabetes: record.hasDiabetes,
        hasAnemia: record.hasAnemia,
        hasPreeclampsia: record.hasPreeclampsia,
        hasGestationalDiabetes: record.hasGestationalDiabetes,
        createdAt: record.createdAt,
        name: record.name,
      }));
      return {
        timestamps: timestamp,
        statusCode: 200,
        path: path,
        error: null,
        result: healthList,
      };
    } catch (error) {
      return {
        timestamps: timestamp,
        statusCode: 500, // Or another appropriate status code based on your error handling
        path: path,
        error: error.message || 'Internal Server Error',
        result: [],
      };
    }
  }

  async update(
    id: string,
    updateHealthDto: UpdateHealthDto,
  ): Promise<{ success: boolean; message: string; result: Health }> {
    const updatedHealthRecord = await this.healthModel
      .findByIdAndUpdate(id, updateHealthDto, { new: true })
      .exec();
    if (!updatedHealthRecord) {
      return {
        success: false,
        message: 'Health record not found',
        result: null,
      };
    }
    return {
      success: true,
      message: 'Health record updated successfully',
      result: updatedHealthRecord,
    };
  }

  async remove(id: string): Promise<{ success: boolean; message: string }> {
    const deletedHealthRecord = await this.healthModel.findByIdAndDelete(id).exec();
    if (!deletedHealthRecord) {
      return {
        success: false,
        message: 'Health record not found',
      };
    }
    return {
      success: true,
      message: 'Health record deleted successfully',
    };
  }
}
