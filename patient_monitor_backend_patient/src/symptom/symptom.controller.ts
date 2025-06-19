import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { SymptomsService } from './symptom.service';
import { CreateSymptomDto } from 'src/users/dto/create-symptom.dto';
import { SymptomDto } from 'src/users/dto/symptom.dto';
import { SearchSymptomDto } from 'src/users/dto/search-symptom.dto';

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

  @Get('search')
  async search(@Query() searchSymptomDto: SearchSymptomDto): Promise<SymptomDto[]> {
    try {
      const symptoms = await this.symptomsService.searchSymptoms(searchSymptomDto);
      if (!symptoms || symptoms.length === 0) {
        throw new HttpException(
          'No symptoms found matching the search criteria',
          HttpStatus.NOT_FOUND,
        );
      }
      return symptoms;
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      throw new HttpException(
        'Failed to search symptoms',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}