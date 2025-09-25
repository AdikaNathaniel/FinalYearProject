import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Visit } from 'src/shared/schema/visit.schema';
import { Patient } from 'src/shared/schema/patient.schema';
import { AntenatalVisitSmsService } from './antenatal-visit-sms.service';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class VisitService {
  private readonly logger = new Logger(VisitService.name);

  constructor(
    @InjectModel(Visit.name) private visitModel: Model<Visit>,
    @InjectModel(Patient.name) private patientModel: Model<Patient>,
    private readonly smsService: AntenatalVisitSmsService,
  ) {}

  async scheduleVisits(patientName: string, dates: Date[]): Promise<Visit[]> {
    const patient = await this.patientModel.findOne({ name: patientName }).exec();
    if (!patient) {
      throw new BadRequestException('Patient not found');
    }

    // Validate number of visits based on pregnancy weeks
    const weeks = patient.weeksOfPregnancy;
    let requiredVisits = 0;

    if (weeks >= 1 && weeks <= 28) {
      requiredVisits = 1; // 1 visit per month
    } else if (weeks > 28 && weeks <= 36) {
      requiredVisits = 2; // 2 visits per month
    } else if (weeks > 36 && weeks <= 42) {
      requiredVisits = 4; // 1 visit per week
    }

    // YYYY-MM-DDTHH:MM:SSZ 
    if (dates.length !== requiredVisits) {
      throw new BadRequestException(
        `For ${weeks} weeks pregnant, exactly ${requiredVisits} visit(s) must be scheduled`,
      );
    }

    // Check for existing visits in the same month
    const existingVisits = await this.visitModel.find({
      patientName,
      visitDate: {
        $gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
        $lt: new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0),
      },
    }).exec();

    if (existingVisits.length > 0) {
      throw new BadRequestException('Visits for this month already scheduled');
    }

    const visits = dates.map(date => ({
      patientName,
      visitDate: date,
      reminderSent: false,
      dailyReminderCount: 0,
    }));

    const createdVisits = await this.visitModel.insertMany(visits);

    // Send SMS notification after successful scheduling
    try {
      await this.smsService.sendVisitScheduleSms(
        patient.phoneNumber,
        patient.name,
        dates
      );
    } catch (error) {
      // Log error but don't fail the operation
      this.logger.error('Failed to send SMS notification:', error);
    }

    return createdVisits;
  }

  async getVisitsByPatient(patientName: string): Promise<Visit[]> {
    return this.visitModel.find({ patientName }).sort({ visitDate: 1 }).exec();
  }






  async getVisitsByDate(date: string): Promise<Visit[]> {
  this.logger.log(`Getting visits for date: ${date}`);
  
  // Create start and end date for the provided date to cover the entire day
  const startDate = new Date(date);
  startDate.setHours(0, 0, 0, 0);
  
  const endDate = new Date(date);
  endDate.setHours(23, 59, 59, 999);
  
  // Find all visits within the specified date range
  return this.visitModel.find({
    visitDate: { 
      $gte: startDate, 
      $lte: endDate 
    }
  }).sort({ visitDate: 1 }).exec();
}


  // Run every day at 9:00 AM
  @Cron('0 0 9 * * *', {
    name: 'dailyVisitReminders',
    timeZone: 'UTC' // Adjust to your local timezone if needed
  })
  async sendDailyVisitReminders(): Promise<void> {
    this.logger.log('Running daily visit reminder cron job');
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // Find all upcoming visits that are today or in the future
    const upcomingVisits = await this.visitModel.find({
      visitDate: { $gte: today },
      // Either no daily reminder sent yet or reminder count is less than days before visit
    }).exec();
    
    for (const visit of upcomingVisits) {
      const visitDate = new Date(visit.visitDate);
      visitDate.setHours(0, 0, 0, 0);
      
      // Calculate days until visit
      const daysUntilVisit = Math.floor((visitDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      
      // Send reminder if it's the visit day or we haven't sent enough daily reminders yet
      if (daysUntilVisit === 0 || (visit.dailyReminderCount < daysUntilVisit)) {
        const patient = await this.patientModel.findOne({ name: visit.patientName }).exec();
        if (!patient) continue;
        
        try {
          // Prepare a message based on whether it's the visit day or a reminder
          let reminderMessage;
          if (daysUntilVisit === 0) {
            await this.smsService.sendVisitScheduleSms(
              patient.phoneNumber,
              patient.name,
              [visit.visitDate]
            );
            
            // Mark final reminder as sent
            await this.visitModel.findByIdAndUpdate(visit._id, { reminderSent: true });
            this.logger.log(`Sent day-of visit reminder to ${patient.name} for visit today`);
          } else {
            await this.smsService.sendVisitScheduleSms(
              patient.phoneNumber,
              patient.name,
              [visit.visitDate]
            );
            
            // Increment the daily reminder count
            await this.visitModel.findByIdAndUpdate(visit._id, { 
              $inc: { dailyReminderCount: 1 } 
            });
            this.logger.log(`Sent reminder to ${patient.name} for visit in ${daysUntilVisit} days`);
          }
        } catch (error) {
          this.logger.error(`Failed to send reminder for visit ${visit._id}:`, error);
        }
      }
    }
  }

  // Kept for backward compatibility or manual triggering
  async sendVisitReminders(): Promise<void> {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    const endOfDay = new Date(tomorrow);
    endOfDay.setHours(23, 59, 59, 999);

    const upcomingVisits = await this.visitModel.find({
      visitDate: { $gte: tomorrow, $lte: endOfDay },
      reminderSent: false,
    }).exec();

    for (const visit of upcomingVisits) {
      const patient = await this.patientModel.findOne({ name: visit.patientName }).exec();
      if (!patient) continue;

      try {
        await this.smsService.sendVisitScheduleSms(
          patient.phoneNumber,
          patient.name,
          [visit.visitDate]
        );
        await this.visitModel.findByIdAndUpdate(visit._id, { reminderSent: true });
      } catch (error) {
        this.logger.error(`Failed to send reminder for visit ${visit._id}:`, error);
      }
    }
  }
}