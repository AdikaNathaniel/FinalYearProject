import { Controller, Get, Post, Param, Body } from '@nestjs/common';
import { VisitService } from './visit.service';
import { Visit } from 'src/shared/schema/visit.schema';

@Controller('visits')
export class VisitController {
  constructor(private readonly visitService: VisitService) {}

  @Post('schedule/:patientName')
  async scheduleVisits(
    @Param('patientName') patientName: string,
    @Body() body: { dates: Date[] },
  ): Promise<Visit[]> {
    return this.visitService.scheduleVisits(patientName, body.dates);
  }

  @Get('patient/:patientName')
  async getVisitsByPatient(
    @Param('patientName') patientName: string,
  ): Promise<Visit[]> {
    return this.visitService.getVisitsByPatient(patientName);
  }

  @Get('send-reminders')
  async sendReminders(): Promise<string> {
    await this.visitService.sendVisitReminders();
    return 'Reminders sent successfully';
  }
}