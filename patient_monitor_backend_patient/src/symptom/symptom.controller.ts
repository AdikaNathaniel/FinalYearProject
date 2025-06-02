import {
  Controller,
  Get,
  Post,
  Body,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { SymptomsService } from './symptom.service';
import { CreateSymptomDto } from 'src/users/dto/create-symptom.dto';
import { SymptomDto } from 'src/users/dto/symptom.dto';

@Controller('symptoms')
export class SymptomsController {
  constructor(private readonly symptomsService: SymptomsService) {}

  @Post()
  async create(@Body() createSymptomDto: CreateSymptomDto): Promise<SymptomDto> {
    try {
      return await this.symptomsService.create(createSymptomDto);
    } catch (error) {
      throw new HttpException(
        'Failed to create symptom record',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get()
  async findAll(): Promise<SymptomDto[]> {
    try {
      return await this.symptomsService.findAll();
    } catch (error) {
      throw new HttpException(
        'Failed to fetch symptoms',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}