import {
  Controller,
  Post,
  Get,
  Put,
  Delete,
  Body,
  Param,
} from '@nestjs/common';
import { EmergencyService } from './emergency.service';
import { CreateContactDto } from 'src/users/dto/create-contact.dto';
import { UpdateContactDto } from 'src/users/dto/update-contact.dto';
import { SendSmsDto } from 'src/users/dto/sms-send.dto';

@Controller('emergency/contacts')
export class EmergencyController {
  constructor(private readonly emergencyService: EmergencyService) {}

  @Post()
  async createContact(@Body() createContactDto: CreateContactDto) {
    // Using a default userId since we're not authenticating
    const userId = 'default-user-id';
    return this.emergencyService.createContact(userId, createContactDto);
  }

  @Get()
  async getAllContacts() {
    const userId = 'default-user-id';
    return this.emergencyService.getAllContacts(userId);
  }

  @Get(':name')
  async getContactByName(@Param('name') name: string) {
    const userId = 'default-user-id';
    return this.emergencyService.getContactByName(userId, name);
  }

  @Put(':name')
  async updateContact(
    @Param('name') name: string,
    @Body() updateContactDto: UpdateContactDto,
  ) {
    const userId = 'default-user-id';
    return this.emergencyService.updateContact(userId, name, updateContactDto);
  }

  @Delete(':name')
  async deleteContact(@Param('name') name: string) {
    const userId = 'default-user-id';
    return this.emergencyService.deleteContact(userId, name);
  }

  @Post('send')
  async sendEmergencySms(@Body() sendSmsDto: SendSmsDto) {
    const userId = 'default-user-id';
    return this.emergencyService.sendEmergencySms(userId, sendSmsDto);
  }
}