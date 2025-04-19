import { Controller, Get, Post, Body, Param, Patch, Delete } from '@nestjs/common';
import { HealthService } from './health.service';
import { CreateHealthDto } from 'src/users/dto/create-health.dto';
import { UpdateHealthDto } from 'src/users/dto/update-health.dto';
import { Health } from 'src/shared/schema/health.schema';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Post()
  create(@Body() createHealthDto: CreateHealthDto): Promise<Health> {
    return this.healthService.create(createHealthDto).then((response) => response.result);
  }

  // @Get()
  // findAll(): Promise<Health[]> {
  //   return this.healthService.findAll().then((response) => response.result);
  // }

  @Get()
  findAll() {
    return this.healthService.findAll(); // Return full response
  }

  // @Get(':id')
  // findOne(@Param('id') id: string): Promise<Health> {
  //   return this.healthService.findOne(id).then((response) => response.result);
  // }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateHealthDto: UpdateHealthDto): Promise<Health> {
    return this.healthService.update(id, updateHealthDto).then((response) => response.result);
  }

  @Delete(':id')
  remove(@Param('id') id: string): Promise<{ success: boolean; message: string }> {
    return this.healthService.remove(id);
  }
}
