import { Controller, Get, Post, Put, Body, Param } from '@nestjs/common';
import { PatientService } from './patient.service';
import { Patient } from 'src/shared/schema/patient.schema';

@Controller('patients')
export class PatientController {
  constructor(private readonly patientService: PatientService) {}

  @Post()
  async create(@Body() patientData: Partial<Patient>): Promise<Patient> {
    return this.patientService.create(patientData);
  }

  @Get(':name')
  async findByName(@Param('name') name: string): Promise<Patient> {
    return this.patientService.findByName(name);
  }

  @Put(':name/weeks')
  async updateWeeksOfPregnancy(
    @Param('name') name: string,
    @Body() body: { weeks: number },
  ): Promise<Patient> {
    return this.patientService.updateWeeksOfPregnancy(name, body.weeks);
  }
}