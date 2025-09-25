import { Controller, Get, Post, Param, Body, HttpException, HttpStatus } from '@nestjs/common';
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


  @Post('/by-date')
async getVisitsByDate(@Body() body: { date: string }) {
  try {
    // Validate date format (YYYY-MM-DD)
    if (!body.date || !/^\d{4}-\d{2}-\d{2}$/.test(body.date)) {
      throw new HttpException('Invalid date format. Use YYYY-MM-DD format.', HttpStatus.BAD_REQUEST);
    }
    
    const visits = await this.visitService.getVisitsByDate(body.date);
    
    // Transform the result to just include patient names if needed
    const patientVisits = visits.map(visit => ({
      patientName: visit.patientName,
      visitDate: visit.visitDate,
      reminderSent: visit.reminderSent
    }));
    
    return {
      success: true,
      message: `Found ${visits.length} visits for date ${body.date}`,
      data: patientVisits
    };
  } catch (error) {
    throw new HttpException(
      error.message || 'Failed to retrieve visits', 
      error.status || HttpStatus.INTERNAL_SERVER_ERROR
    );
  }
}

}