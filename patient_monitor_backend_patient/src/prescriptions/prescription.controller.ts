import { Controller, Get, Post, Body, Delete } from '@nestjs/common';
import { PrescriptionsService } from './prescription.service';
import { CreatePrescriptionDto } from 'src/users/dto/create-prescription.dto';
import { UpdatePrescriptionDto } from 'src/users/dto/update-prescription.dto';

@Controller('prescriptions')
export class PrescriptionsController {
  constructor(private readonly prescriptionsService: PrescriptionsService) {}

  @Post()
  async create(@Body() createPrescriptionDto: CreatePrescriptionDto) {
    return this.prescriptionsService.create(createPrescriptionDto);
  }

  @Get()
  async findAll() {
    return this.prescriptionsService.findAll();
  }

  @Delete('last')
  async removeLastPrescription() {
    return this.prescriptionsService.removeLastPrescription();
  }
}
