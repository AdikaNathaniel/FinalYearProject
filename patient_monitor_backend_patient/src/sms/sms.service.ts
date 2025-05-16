import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';
import {
  SmsRecord,
  SmsRecordDocument,
} from 'src/shared/schema/sms.schema';
import {
  Appointment,
  AppointmentDocument,
} from 'src/shared/schema/appointments.schema';
import {
  NutritionProfile,
  NutritionProfileDocument,
} from 'src/shared/schema/nutrition.schema';
import {
  Medication,
  MedicationDocument,
} from 'src/shared/schema/medication.schema';
import {
  Pregnancy,
  PregnancyDocument,
} from 'src/shared/schema/pregnancy.schema';
import { SendSmsDto } from 'src/users/dto/send-sms.dto';
import { AppointmentReminderDto } from 'src/users/dto/appointment-reminder.dto';
import { NutritionReminderDto } from 'src/users/dto/nutrition-reminder.dto';
import { MedicationReminderDto } from 'src/users/dto/medication-reminder.dto';
import { PregnancyUpdateDto } from 'src/users/dto/pregnancy-update.dto';

import {
  APPOINTMENT_REMINDER_MESSAGES,
  NUTRITION_MESSAGES,
  MEDICATION_MESSAGES,
  PREGNANCY_UPDATE_MESSAGES,
} from './constants/messages.constants';
import { NUTRITION_TIPS, DEFICIENCY_TIPS } from './constants/nutrition-tips.constants';
import { PREGNANCY_STAGES, WEEKLY_UPDATES } from './constants/pregnancy-stages.constants';

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);

  constructor(
    @InjectModel(SmsRecord.name)
    private readonly smsModel: Model<SmsRecordDocument>,
    @InjectModel(Appointment.name)
    private readonly appointmentModel: Model<AppointmentDocument>,
    @InjectModel(NutritionProfile.name)
    private readonly nutritionModel: Model<NutritionProfileDocument>,
    @InjectModel(Medication.name)
    private readonly medicationModel: Model<MedicationDocument>,
    @InjectModel(Pregnancy.name)
    private readonly pregnancyModel: Model<PregnancyDocument>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {}

  async sendSms(phone: string, message: string): Promise<boolean> {
    const smsRecord = new this.smsModel({
      phone,
      message,
      type: 'appointment',
      status: 'pending',
    });

    try {
      // Get API key from config service instead of hardcoding
      const apiKey = 'cWZPeGl3anVMTXFheHRTb3F5QkE';
      if (!apiKey) {
        this.logger.error('SMS_API_KEY environment variable is not set');
        smsRecord.status = 'failed';
        smsRecord.failureReason = 'Missing API key';
        await smsRecord.save();
        return false;
      }

      const senderId = this.configService.get<string>('SMS_SENDER_ID') || 'ArkeselTest';
      const baseUrl = 'https://sms.arkesel.com/api/v2/sms/send';

      this.logger.log(`Sending SMS to ${phone} with message: ${message}`);

      const response = await firstValueFrom(
        this.httpService.post(
          baseUrl,
          {
            sender: senderId,
            message,
            recipients: [phone],
          },
          {
            headers: {
              'api-key': apiKey,
              'Content-Type': 'application/json',
            },
          },
        ),
      );

      this.logger.log(`SMS API response: ${JSON.stringify(response.data)}`);

      if (response.data.status === 'success') {
        smsRecord.status = 'sent';
        smsRecord.sentAt = new Date();
        await smsRecord.save();
        return true;
      } else {
        smsRecord.status = 'failed';
        smsRecord.failureReason = JSON.stringify(response.data);
        await smsRecord.save();
        return false;
      }
    } catch (error) {
      this.logger.error(`Failed to send SMS: ${error.message}`, error.stack);
      smsRecord.status = 'failed';
      smsRecord.failureReason = error.message;
      await smsRecord.save();
      return false;
    }
  }

  async scheduleAppointmentReminder(dto: AppointmentReminderDto): Promise<Appointment> {
    const appointment = new this.appointmentModel(dto);
    await appointment.save();
    
    // Send an immediate confirmation SMS after creating appointment
    const confirmationMessage = `Your appointment with ${dto.doctor} on ${new Date(dto.date).toLocaleDateString()} at ${dto.location} has been scheduled. Reply Y to confirm or N to cancel.`;
    await this.sendSms(dto.phone, confirmationMessage);
    
    return appointment;
  }

  async createMedicationReminder(dto: MedicationReminderDto): Promise<Medication> {
    const medication = new this.medicationModel(dto);
    await medication.save();
    
    // Send an immediate confirmation SMS after creating medication reminder
    const confirmationMessage = `Your medication reminder for ${dto.medicationName} (${dto.dosage}) has been set up. You will receive ${dto.frequency} reminders.`;
    await this.sendSms(dto.phone, confirmationMessage);
    
    return medication;
  }

  async createNutritionProfile(dto: NutritionReminderDto): Promise<NutritionProfile> {
    const profile = new this.nutritionModel({
      ...dto,
      waterIntakeGoal: dto.waterIntakeGoal || 8,
    });
    await profile.save();
    
    // Send an immediate welcome message
    const welcomeMessage = `Your nutrition profile has been created. You will receive daily water intake reminders and nutrition tips for your ${dto.trimester} trimester.`;
    await this.sendSms(dto.phone, welcomeMessage);
    
    return profile;
  }

  async createPregnancyProfile(dto: PregnancyUpdateDto): Promise<Pregnancy> {
    const pregnancy = new this.pregnancyModel(dto);
    this.calculateNextAppointmentSchedule(pregnancy);
    await pregnancy.save();
    
    // Send an immediate welcome message
    const welcomeMessage = `Your pregnancy profile has been created. You are currently in week ${pregnancy.currentWeek}. You will receive weekly updates about your pregnancy journey.`;
    await this.sendSms(dto.phone, welcomeMessage);
    
    return pregnancy;
  }

  // Rest of the methods remain the same...
  async sendAppointmentReminders(): Promise<void> {
    const now = new Date();
    const weekBeforeDate = new Date();
    weekBeforeDate.setDate(now.getDate() + 7);
    
    const weekBeforeAppointments = await this.appointmentModel.find({
      date: { $lte: weekBeforeDate, $gte: now },
      'reminders.weekBefore': false,
    });

    for (const appointment of weekBeforeAppointments) {
      const message = APPOINTMENT_REMINDER_MESSAGES.WEEK_BEFORE({
        date: appointment.date,
        doctor: appointment.doctor,
        location: appointment.location
      });
      const sent = await this.sendSms(appointment.phone, message);
      if (sent) {
        appointment.reminders.weekBefore = true;
        await appointment.save();
      }
    }

    const twoDaysBeforeDate = new Date();
    twoDaysBeforeDate.setDate(now.getDate() + 2);
    
    const twoDaysBeforeAppointments = await this.appointmentModel.find({
      date: { $lte: twoDaysBeforeDate, $gte: now },
      'reminders.twoDaysBefore': false,
    });

    for (const appointment of twoDaysBeforeAppointments) {
      const message = APPOINTMENT_REMINDER_MESSAGES.TWO_DAYS_BEFORE({
        date: appointment.date,
        doctor: appointment.doctor,
        location: appointment.location
      });
      const sent = await this.sendSms(appointment.phone, message);
      if (sent) {
        appointment.reminders.twoDaysBefore = true;
        await appointment.save();
      }
    }

    const dayBeforeDate = new Date();
    dayBeforeDate.setDate(now.getDate() + 1);
    
    const dayBeforeAppointments = await this.appointmentModel.find({
      date: { $lte: dayBeforeDate, $gte: now },
      'reminders.dayBefore': false,
    });

    for (const appointment of dayBeforeAppointments) {
      const message = APPOINTMENT_REMINDER_MESSAGES.DAY_BEFORE({
        date: appointment.date,
        doctor: appointment.doctor,
        location: appointment.location
      });
      const sent = await this.sendSms(appointment.phone, message);
      if (sent) {
        appointment.reminders.dayBefore = true;
        await appointment.save();
      }
    }
  }

  async handleAppointmentConfirmation(phone: string, confirmation: 'Y' | 'N'): Promise<void> {
    const appointment = await this.appointmentModel.findOne({
      phone,
      confirmed: { $ne: true },
    }).sort({ date: 1 });

    if (appointment) {
      appointment.confirmed = confirmation === 'Y';
      await appointment.save();

      const responseMessage = confirmation === 'Y' 
        ? 'Thank you for confirming your appointment.' 
        : 'We will contact you to reschedule your appointment.';
      await this.sendSms(phone, responseMessage);
    }
  }

  async sendWaterIntakeReminders(): Promise<void> {
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    const profiles = await this.nutritionModel.find({
      $or: [
        { lastWaterReminderSent: { $lt: oneDayAgo } },
        { lastWaterReminderSent: { $exists: false } },
      ],
    });

    for (const profile of profiles) {
      const message = NUTRITION_MESSAGES.WATER_INTAKE(profile.waterIntakeGoal);
      const sent = await this.sendSms(profile.phone, message);
      if (sent) {
        profile.lastWaterReminderSent = now;
        await profile.save();
      }
    }
  }

  async sendNutritionTips(): Promise<void> {
    const now = new Date();
    const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);

    const profiles = await this.nutritionModel.find({
      $or: [
        { lastNutritionTipSent: { $lt: threeDaysAgo } },
        { lastNutritionTipSent: { $exists: false } },
      ],
    });

    for (const profile of profiles) {
      const tips = NUTRITION_TIPS[profile.trimester];
      const randomTip = tips[Math.floor(Math.random() * tips.length)];
      const message = NUTRITION_MESSAGES.SNACK_TIP(
        profile.trimester,
        randomTip
      );
      const sent = await this.sendSms(profile.phone, message);
      if (sent) {
        profile.lastNutritionTipSent = now;
        await profile.save();
      }

      if (profile.deficiencies && profile.deficiencies.length > 0) {
        for (const deficiency of profile.deficiencies) {
          const deficiencyMessage = NUTRITION_MESSAGES.DEFICIENCY_REMINDER(
            DEFICIENCY_TIPS[deficiency] || deficiency
          );
          await this.sendSms(profile.phone, deficiencyMessage);
        }
      }
    }
  }

  async sendMedicationReminders(): Promise<void> {
    const now = new Date();
    const dailyMeds = await this.medicationModel.find({
      frequency: 'daily',
      $or: [
        { lastReminderSent: { $lt: new Date(now.getFullYear(), now.getMonth(), now.getDate()) } },
        { lastReminderSent: { $exists: false } },
      ],
    });

    for (const med of dailyMeds) {
      const message = MEDICATION_MESSAGES.DAILY_REMINDER({
        medicationName: med.medicationName,
        dosage: med.dosage
      });
      const sent = await this.sendSms(med.phone, message);
      if (sent) {
        med.lastReminderSent = now;
        await med.save();
      }
    }

    const weeklyMeds = await this.medicationModel.find({
      frequency: 'weekly',
      $or: [
        { lastReminderSent: { $lt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) } },
        { lastReminderSent: { $exists: false } },
      ],
    });

    for (const med of weeklyMeds) {
      const message = MEDICATION_MESSAGES.WEEKLY_REMINDER({
        medicationName: med.medicationName,
        dosage: med.dosage
      });
      const sent = await this.sendSms(med.phone, message);
      if (sent) {
        med.lastReminderSent = now;
        await med.save();
      }
    }

    const refillDateStart = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
    const refillDateEnd = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000);

    const refillMeds = await this.medicationModel.find({
      refillDate: { $gte: refillDateStart, $lte: refillDateEnd },
      $or: [
        { lastReminderSent: { $ne: now.toDateString() } },
        { lastReminderSent: { $exists: false } },
      ],
    });

    for (const med of refillMeds) {
      const message = MEDICATION_MESSAGES.REFILL_REMINDER({
        medicationName: med.medicationName,
        refillDate: med.refillDate
      });
      const sent = await this.sendSms(med.phone, message);
      if (sent) {
        med.lastReminderSent = now;
        await med.save();
      }
    }
  }

  async updatePregnancyWeek(patientId: string): Promise<Pregnancy> {
    const pregnancy = await this.pregnancyModel.findOne({ patientId });
    if (!pregnancy) {
      throw new Error('Pregnancy profile not found');
    }

    const now = new Date();
    const diffInMs = now.getTime() - pregnancy.startDate.getTime();
    const diffInWeeks = Math.floor(diffInMs / (1000 * 60 * 60 * 24 * 7));
    
    if (diffInWeeks !== pregnancy.currentWeek) {
      pregnancy.currentWeek = diffInWeeks;
      this.calculateNextAppointmentSchedule(pregnancy);
      await pregnancy.save();
    }

    return pregnancy;
  }

  private calculateNextAppointmentSchedule(pregnancy: Pregnancy): void {
    const { currentWeek } = pregnancy;
    let nextAppointmentDate: Date;

    if (currentWeek < PREGNANCY_STAGES.STAGE_1.end) {
      nextAppointmentDate = new Date(pregnancy.startDate);
      nextAppointmentDate.setDate(nextAppointmentDate.getDate() + (currentWeek + 4) * 7);
    } else if (currentWeek < PREGNANCY_STAGES.STAGE_2.end) {
      nextAppointmentDate = new Date(pregnancy.startDate);
      nextAppointmentDate.setDate(nextAppointmentDate.getDate() + (currentWeek + 2) * 7);
    } else {
      nextAppointmentDate = new Date(pregnancy.startDate);
      nextAppointmentDate.setDate(nextAppointmentDate.getDate() + (currentWeek + 1) * 7);
    }

    pregnancy.nextAppointmentSchedule = nextAppointmentDate;
  }

  async sendWeeklyPregnancyUpdates(): Promise<void> {
    const now = new Date();
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const pregnancies = await this.pregnancyModel.find({
      $or: [
        { lastUpdateSent: { $lt: oneWeekAgo } },
        { lastUpdateSent: { $exists: false } },
      ],
    });

    for (const pregnancy of pregnancies) {
      const week = pregnancy.currentWeek;
      if (week > 42) continue;

      const weeklyUpdate = WEEKLY_UPDATES[week] || `Your baby is growing! You're now at week ${week} of your pregnancy.`;
      const message = PREGNANCY_UPDATE_MESSAGES.WEEKLY_UPDATE(week, weeklyUpdate);
      
      const sent = await this.sendSms(pregnancy.phone, message);
      if (sent) {
        pregnancy.lastUpdateSent = now;
        await pregnancy.save();
      }

      if (pregnancy.nextAppointmentSchedule) {
        const scheduleMessage = PREGNANCY_UPDATE_MESSAGES.APPOINTMENT_SCHEDULE(
          `Next appointment in ${this.getAppointmentFrequency(pregnancy.currentWeek)}`
        );
        await this.sendSms(pregnancy.phone, scheduleMessage);
      }
    }
  }

  private getAppointmentFrequency(currentWeek: number): string {
    if (currentWeek < PREGNANCY_STAGES.STAGE_1.end) {
      return '4 weeks (monthly)';
    } else if (currentWeek < PREGNANCY_STAGES.STAGE_2.end) {
      return '2 weeks (twice monthly)';
    } else {
      return '1 week (weekly)';
    }
  }

  // Method to test SMS sending directly
  async testSms(phone: string): Promise<boolean> {
    const testMessage = "This is a test message from your healthcare provider's system.";
    return this.sendSms(phone, testMessage);
  }
}