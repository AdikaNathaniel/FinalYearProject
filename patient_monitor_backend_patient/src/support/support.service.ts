// src/support/support.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Support } from 'src/shared/schema/support.schema';
import { CreateSupportDto } from 'src/users/dto/create-support.dto';
import { UpdateSupportDto } from 'src/users/dto/update-support.dto';
import { SupportSmsService } from './sms-support.service';

@Injectable()
export class SupportService {
  constructor(
    @InjectModel(Support.name) private readonly supportModel: Model<Support>,
    private readonly smsService: SupportSmsService,
  ) {}

  async create(createSupportDto: CreateSupportDto): Promise<Support> {
    const support = await this.supportModel.create(createSupportDto);
    await this.smsService.sendSupportSms(support);
    return support;
  }

  async findAll(): Promise<Support[]> {
    return this.supportModel.find().exec();
  }

  async findById(id: string): Promise<Support> {
    const support = await this.supportModel.findById(id).exec();
    if (!support) throw new NotFoundException('Support request not found');
    return support;
  }

  async findByName(name: string): Promise<Support[]> {
    return this.supportModel.find({ name: new RegExp(name, 'i') }).exec();
  }

  


async update(id: string, updateDto: UpdateSupportDto): Promise<Support> {
  const updated = await this.supportModel
    .findByIdAndUpdate(id, updateDto, { new: true })
    .exec();

  if (!updated) throw new NotFoundException('Support request not found');

  // Send updated SMS
  await this.smsService.sendSupportSms(updated);

  return updated;
}


  async delete(id: string): Promise<void> {
    const result = await this.supportModel.findByIdAndDelete(id).exec();
    if (!result) throw new NotFoundException('Support request not found');
  }
}
