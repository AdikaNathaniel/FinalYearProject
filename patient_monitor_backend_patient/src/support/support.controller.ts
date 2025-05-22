// src/support/support.controller.ts
import { Controller, Post, Get, Put, Delete, Param, Body } from '@nestjs/common';
import { SupportService } from './support.service';
import { CreateSupportDto } from 'src/users/dto/create-support.dto';
import { UpdateSupportDto } from 'src/users/dto/update-support.dto';

@Controller('support')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post()
  create(@Body() dto: CreateSupportDto) {
    return this.supportService.create(dto);
  }

  @Get()
  findAll() {
    return this.supportService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.supportService.findById(id);
  }

  @Get('by-name/:name')
  findByName(@Param('name') name: string) {
    return this.supportService.findByName(name);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateSupportDto) {
    return this.supportService.update(id, dto);
  }

  @Delete(':id')
  delete(@Param('id') id: string) {
    return this.supportService.delete(id);
  }
}
