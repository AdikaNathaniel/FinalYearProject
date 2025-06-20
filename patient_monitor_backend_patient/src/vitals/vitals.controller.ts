import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { VitalsService } from './vitals.service';
import { CreateVitalDto } from 'src/users/dto/create-vital.dto';
import { VitalDto } from 'src/users/dto/vital.dto';

@Controller('vitals')
export class VitalsController {
  constructor(private readonly vitalsService: VitalsService) {}

  @Post()
  async create(@Body() createVitalDto: CreateVitalDto): Promise<VitalDto> {
    return this.vitalsService.create(createVitalDto);
  }

  @Get()
  async findAll(): Promise<VitalDto[]> {
    return this.vitalsService.findAll();
  }

  @Get(':patientId')
  async findByPatientId(@Param('patientId') patientId: string): Promise<VitalDto[]> {
    return this.vitalsService.findByPatientId(patientId);
  }
}