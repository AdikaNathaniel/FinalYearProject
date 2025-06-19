import {
    Controller,
    Post,
    Body,
    Get,
    Param,
    Query,
  } from '@nestjs/common';
  import { SmsService } from './sms.service';
  import { SendSmsDto } from 'src/users/dto/send-sms.dto';
  import { AppointmentReminderDto } from 'src/users/dto/appointment-reminder.dto';
  import { NutritionReminderDto } from 'src/users/dto/nutrition-reminder.dto';
  import { MedicationReminderDto } from 'src/users/dto/medication-reminder.dto';
  import { PregnancyUpdateDto } from 'src/users/dto/pregnancy-update.dto';

import { HttpException, HttpStatus } from '@nestjs/common';
  
  @Controller('sms')
export class SmsController {
  constructor(private readonly smsService: SmsService) {}

  @Post('send')
  async sendSms(@Body() dto: SendSmsDto) {
    return this.smsService.sendSms(dto.phone, dto.message);
  }

  @Post('appointments/schedule')
  async scheduleAppointment(@Body() dto: AppointmentReminderDto) {
    return this.smsService.scheduleAppointmentReminder(dto);
  }

  @Get('appointments/send-reminders')
  async sendAppointmentReminders() {
    return this.smsService.sendAppointmentReminders();
  }

  @Post('appointments/confirm')
  async confirmAppointment(
    @Query('phone') phone: string,
    @Query('confirmation') confirmation: 'Y' | 'N',
  ) {
    return this.smsService.handleAppointmentConfirmation(phone, confirmation);
  }

  @Post('nutrition/profile')
  async createNutritionProfile(@Body() dto: NutritionReminderDto) {
    return this.smsService.createNutritionProfile(dto);
  }

  @Get('nutrition/send-water-reminders')
  async sendWaterIntakeReminders() {
    return this.smsService.sendWaterIntakeReminders();
  }

  @Get('nutrition/send-tips')
  async sendNutritionTips() {
    return this.smsService.sendNutritionTips();
  }

  @Post('medications/schedule')
  async scheduleMedication(@Body() dto: MedicationReminderDto) {
    return this.smsService.createMedicationReminder(dto);
  }

  @Get('medications/send-reminders')
  async sendMedicationReminders() {
    return this.smsService.sendMedicationReminders();
  }

  @Post('pregnancy/profile')
  async createPregnancyProfile(@Body() dto: PregnancyUpdateDto) {
    return this.smsService.createPregnancyProfile(dto);
  }

  @Get('pregnancy/update-week/:patientId')
  async updatePregnancyWeek(@Param('patientId') patientId: string) {
    return this.smsService.updatePregnancyWeek(patientId);
  }

  @Get('pregnancy/send-updates')
  async sendWeeklyPregnancyUpdates() {
    return this.smsService.sendWeeklyPregnancyUpdates();
  }

  @Post('test')
  async testSms(@Body() data: { phone: string }) {
    if (!data.phone) {
      throw new HttpException('Phone number is required', HttpStatus.BAD_REQUEST);
    }

    const result = await this.smsService.testSms(data.phone);
    
    if (result) {
      return { success: true, message: 'Test SMS sent successfully' };
    } else {
      throw new HttpException('Failed to send test SMS', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

}

// cWZPeGl3anVMTXFheHRTb3F5QkE