import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { VitalsHealthData, InputMethod } from 'src/shared/schema/vitals-health-data.schema';
import { CreateVitalsHealthDataDto } from 'src/users/dto/create-vitals-health-data.dto';
import { UpdateVitalsHealthDataDto } from 'src/users/dto/update-vitals-health-data.dto';

@Injectable()
export class VitalsHealthDataService {
  constructor(
    @InjectModel(VitalsHealthData.name) private vitalsHealthDataModel: Model<VitalsHealthData>,
  ) {}

  // ✅ Create vitals record
  async create(createVitalsHealthDataDto: CreateVitalsHealthDataDto, userId?: string): Promise<VitalsHealthData> {
    const createdVitalsHealthData = new this.vitalsHealthDataModel({
      ...createVitalsHealthDataDto,
      userId: userId || createVitalsHealthDataDto.userId, // allow from DTO or param
      timestamp: createVitalsHealthDataDto.timestamp || new Date(),
    });
    return createdVitalsHealthData.save();
  }

  // ✅ Get vitals (for all patients or single user) with pagination + date filter
  async findAll(
    userId?: string,
    page: number = 1,
    limit: number = 10,
    startDate?: Date,
    endDate?: Date
  ): Promise<{ data: VitalsHealthData[]; total: number; page: number; pages: number }> {
    const query: any = {};

    // If userId is provided → filter by user
    if (userId) query.userId = userId;

    // Date filtering
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = startDate;
      if (endDate) query.timestamp.$lte = endDate;
    }

    const skip = (page - 1) * limit;
    const total = await this.vitalsHealthDataModel.countDocuments(query);
    const data = await this.vitalsHealthDataModel
      .find(query)
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit)
      .exec();

    return {
      data,
      total,
      page,
      pages: Math.ceil(total / limit),
    };
  }

  // ✅ Get one record by ID + optional user filter
  async findOne(id: string, userId?: string): Promise<VitalsHealthData> {
    const query: any = { _id: id };
    if (userId) query.userId = userId;

    const vitalsHealthData = await this.vitalsHealthDataModel.findOne(query).exec();
    if (!vitalsHealthData) {
      throw new NotFoundException('Vitals health data record not found');
    }
    return vitalsHealthData;
  }

  // ✅ Update record
  async update(
    id: string,
    updateVitalsHealthDataDto: UpdateVitalsHealthDataDto,
    userId?: string,
  ): Promise<VitalsHealthData> {
    const query: any = { _id: id };
    if (userId) query.userId = userId;

    const updatedVitalsHealthData = await this.vitalsHealthDataModel
      .findOneAndUpdate(query, updateVitalsHealthDataDto, { new: true, runValidators: true })
      .exec();

    if (!updatedVitalsHealthData) {
      throw new NotFoundException('Vitals health data record not found');
    }
    return updatedVitalsHealthData;
  }

  // ✅ Delete record
  async remove(id: string, userId?: string): Promise<VitalsHealthData> {
    const query: any = { _id: id };
    if (userId) query.userId = userId;

    const deletedVitalsHealthData = await this.vitalsHealthDataModel.findOneAndDelete(query).exec();

    if (!deletedVitalsHealthData) {
      throw new NotFoundException('Vitals health data record not found');
    }
    return deletedVitalsHealthData;
  }

  // ✅ Get latest record for a patient
  async getLatestVitalsHealthData(userId: string): Promise<VitalsHealthData> {
    return this.vitalsHealthDataModel.findOne({ userId }).sort({ timestamp: -1 }).exec();
  }

  // ✅ Get vitals by input method (manual/wearable) with pagination
  async getVitalsHealthDataByMethod(
    userId: string,
    method: InputMethod,
    page: number = 1,
    limit: number = 10,
  ): Promise<{ data: VitalsHealthData[]; total: number; page: number; pages: number }> {
    const query = { userId, inputMethod: method };
    const skip = (page - 1) * limit;
    const total = await this.vitalsHealthDataModel.countDocuments(query);
    const data = await this.vitalsHealthDataModel
      .find(query)
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit)
      .exec();

    return {
      data,
      total,
      page,
      pages: Math.ceil(total / limit),
    };
  }
}
