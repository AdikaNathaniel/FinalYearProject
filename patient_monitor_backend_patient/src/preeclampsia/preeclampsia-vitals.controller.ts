import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Put,
  Delete,
} from '@nestjs/common';
import { PreeclampsiaVitalsService } from './preeclampsia-vitals.service';
import { CreatePreeclampsiaVitalsDto } from 'src/users/dto/create-preeclampsia-vitals.dto';
import { UpdatePreeclampsiaVitalsDto } from 'src/users/dto/update-preeclampsia-vitals.dto';
import { PreeclampsiaVitalsResponseDto } from 'src/users/dto/preeclampsia-vitals-response.dto';

@Controller('preeclampsia-vitals')
export class PreeclampsiaVitalsController {
  constructor(private readonly preeclampsiaVitalsService: PreeclampsiaVitalsService) {}

  @Post()
  async create(
    @Body() createPreeclampsiaVitalsDto: CreatePreeclampsiaVitalsDto,
  ): Promise<PreeclampsiaVitalsResponseDto> {
    return this.preeclampsiaVitalsService.create(createPreeclampsiaVitalsDto);
  }

  @Get()
  async findAll(): Promise<PreeclampsiaVitalsResponseDto[]> {
    return this.preeclampsiaVitalsService.findAll();
  }

  @Get(':patientId')
  async findByPatientId(
    @Param('patientId') patientId: string,
  ): Promise<PreeclampsiaVitalsResponseDto[]> {
    return this.preeclampsiaVitalsService.findByPatientId(patientId);
  }

  @Put(':patientId')
  async update(
    @Param('patientId') patientId: string,
    @Body() updatePreeclampsiaVitalsDto: UpdatePreeclampsiaVitalsDto,
  ): Promise<PreeclampsiaVitalsResponseDto> {
    return this.preeclampsiaVitalsService.update(patientId, updatePreeclampsiaVitalsDto);
  }

  @Delete(':patientId')
  async delete(@Param('patientId') patientId: string): Promise<void> {
    return this.preeclampsiaVitalsService.deleteByPatientId(patientId);
  }
}