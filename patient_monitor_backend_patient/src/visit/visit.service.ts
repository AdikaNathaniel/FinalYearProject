import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Visit } from 'src/shared/schema/visit.schema';
import { Patient } from 'src/shared/schema/patient.schema';
import { AntenatalVisitSmsService } from './antenatal-visit-sms.service';

@Injectable()
export class VisitService {
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
      console.error('Failed to send SMS notification:', error);
    }

    return createdVisits;
  }

  async getVisitsByPatient(patientName: string): Promise<Visit[]> {
    return this.visitModel.find({ patientName }).sort({ visitDate: 1 }).exec();
  }

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
        console.error(`Failed to send reminder for visit ${visit._id}:`, error);
      }
    }
  }
}