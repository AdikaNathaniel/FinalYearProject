import {
  Controller,
  Post,
  Body,
  BadRequestException,
  Get,
  Param,
  Patch,
  Delete,
} from '@nestjs/common';
import { PinService } from './pin.service';
import { CreatePinDto } from 'src/users/dto/create-pin.dto';
import { VerifyPinDto } from 'src/users/dto/verify-pin.dto';
import { UpdatePinDto } from 'src/users/dto/update-pin.dto';

@Controller('pin')
export class PinController {
  constructor(private readonly pinService: PinService) {}

  @Post()
  async createPin(@Body() createPinDto: CreatePinDto & { phone: string }) {
    return this.pinService.createPin(createPinDto);
  }

  @Post('verify')
  async verifyPin(@Body() verifyPinDto: VerifyPinDto) {
    return this.pinService.verifyPin(verifyPinDto);
  }

  @Patch()
  async updatePin(@Body() updatePinDto: UpdatePinDto & { phone: string }) {
    return this.pinService.updatePin(updatePinDto);
  }

 
  @Delete(':userId')
  async deletePin(@Param('userId') userId: string) {
    return this.pinService.deletePin(userId);
  }

  @Get(':userId/has-pin')
  async hasPin(@Param('userId') userId: string) {
    return { hasPin: await this.pinService.hasPin(userId) };
  }
}