import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreatePrescriptionDto } from 'src/users/dto/create-prescription.dto';
// import { UpdatePrescriptionDto } from 'src/users/dto/update-prescription.dto';
import { Prescription } from 'src/shared/schema/prescriptions.schema';

@Injectable()
export class PrescriptionsService {
  constructor(@InjectModel(Prescription.name) private prescriptionModel: Model<Prescription>) {}

  async create(createPrescriptionDto: CreatePrescriptionDto): Promise<Prescription> {
    const createdPrescription = new this.prescriptionModel({
      ...createPrescriptionDto,
      start_date: new Date(createPrescriptionDto.start_date),
      end_date: new Date(createPrescriptionDto.end_date),
      createdAt: new Date(), // Automatically set the creation time
    });
    return createdPrescription.save();
  }

  async findAll(): Promise<any> {
    const prescriptions = await this.prescriptionModel.find().exec();
    return {
      success: true,
      message: 'Prescriptions fetched successfully',
      result: prescriptions,
    };
  }

  async removeLastPrescription(): Promise<{ success: boolean; message: string }> {
    const lastPrescription = await this.prescriptionModel.findOne().sort({ createdAt: -1 }).exec();
    if (!lastPrescription) {
      return { success: false, message: 'No prescriptions found to delete' };
    }
    await this.prescriptionModel.deleteOne({ _id: lastPrescription._id }).exec();
    return { success: true, message: 'Last prescription successfully deleted' };
  }
}
