import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
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
import {
  PendingReminder,
  PendingReminderDocument,
} from 'src/shared/schema/pending-reminder.schema';
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
  private readonly smsApiUrl = 'https://sms.arkesel.com/api/v2/sms/send';
  private readonly senderId = 'Awo)Pa';

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
    @InjectModel(PendingReminder.name)
    private readonly pendingReminderModel: Model<PendingReminderDocument>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Core SMS sending functionality using Arkesel API
   */
async sendSms(phone: string, message: string): Promise<boolean> {
    const formattedPhone = this.formatPhoneNumber(phone);
    const smsRecord = await this.createSmsRecord(formattedPhone, message);

    try {
      const apiKey = this.configService.get<string>('SMS_API_KEY') || 'R0lBd2RtanJrd3lsdmhjV1lrR2s';
      if (!apiKey) {
        throw new Error('SMS_API_KEY environment variable is not set');
      }

      this.logger.log(`Sending SMS to ${formattedPhone} with message: ${message}`);

      const response = await firstValueFrom(
        this.httpService.post(
          this.smsApiUrl,
          {
            sender: this.senderId,
            message,
            recipients: [formattedPhone],
          },
          {
            headers: { 'api-key': apiKey },
            timeout: 10000,
          },
        ),
      );

      this.logger.debug(`SMS API response: ${JSON.stringify(response.data)}`);

      if (response.data.status === 'success') {
        smsRecord.status = 'sent';
        smsRecord.sentAt = new Date();
        await smsRecord.save();
        return true;
      } else {
        throw new Error(`SMS API returned non-success status: ${JSON.stringify(response.data)}`);
      }
    } catch (error) {
      await this.handleSmsError(error, smsRecord, formattedPhone, message);
      return false;
    }
  }

  /**
   * Appointment Reminder Functions
   */
async scheduleAppointmentReminder(dto: AppointmentReminderDto): Promise<Appointment> {
  const appointment = new this.appointmentModel({
    ...dto,
    status: 'pending',
    reminders: {
      weekBefore: true,
      twoDaysBefore: true,
      dayBefore: true,
    },
  });
  await appointment.save();
  
 const confirmationMessage = `Dear ${dto.patientName}, Dr. ${dto.doctor} has scheduled an appointment to see you for ${dto.purpose || 'a checkup'} on ${new Date(dto.date).toLocaleDateString()} at ${dto.location || 'our clinic'}. Reply Y to confirm or N to reschedule.`.trim();


  await this.ensureSmsSent(
    dto.phone, 
    confirmationMessage, 
    'appointment', 
    new Types.ObjectId(appointment._id.toString())
  );
  
  return appointment;
}


  async sendAppointmentReminders(): Promise<void> {
    const now = new Date();
    
    await this.processAppointmentReminders(
      new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000),
      now,
      'weekBefore',
      APPOINTMENT_REMINDER_MESSAGES.WEEK_BEFORE
    );

    await this.processAppointmentReminders(
      new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000),
      now,
      'twoDaysBefore',
      APPOINTMENT_REMINDER_MESSAGES.TWO_DAYS_BEFORE
    );

    await this.processAppointmentReminders(
      new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000),
      now,
      'dayBefore',
      APPOINTMENT_REMINDER_MESSAGES.DAY_BEFORE
    );
  }

  async handleAppointmentConfirmation(phone: string, confirmation: 'Y' | 'N'): Promise<void> {
    const appointment = await this.appointmentModel.findOne({
      phone,
      confirmed: { $ne: true },
    }).sort({ date: 1 });

    if (appointment) {
      appointment.status = confirmation === 'Y' ? 'confirmed' : 'canceled';
      appointment.confirmed = confirmation === 'Y';
      appointment.confirmedAt = new Date(); // optionally mark when they confirmed

      await appointment.save();

      const responseMessage = confirmation === 'Y' 
        ? 'Thank you for confirming your appointment.' 
        : 'We will contact you to reschedule your appointment.';
      await this.ensureSmsSent(phone, responseMessage);
    }
  }

  /**
   * Nutrition Reminder Functions
   */
  async createNutritionProfile(dto: NutritionReminderDto): Promise<NutritionProfile> {
    const profile = new this.nutritionModel({
      ...dto,
      waterIntakeGoal: dto.waterIntakeGoal || 8,
    });
    await profile.save();
    
    const welcomeMessage = `Dear ${dto.patientName}, your nutrition profile has been created. You will receive daily water intake reminders and nutrition tips for your ${dto.trimester} trimester.`;
    await this.ensureSmsSent(
      dto.phone, 
      welcomeMessage, 
      'nutrition', 
      new Types.ObjectId(profile._id.toString())
    );
    
    return profile;
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
  const message = NUTRITION_MESSAGES.WATER_INTAKE(profile.patientName, profile.waterIntakeGoal); // Pass patientName here
  const sent = await this.ensureSmsSent(
    profile.phone, 
    message, 
    'nutrition', 
    new Types.ObjectId(profile._id.toString())
  );
  
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
      const message = NUTRITION_MESSAGES.SNACK_TIP(profile.patientName,profile.trimester, randomTip);
      
      const sent = await this.ensureSmsSent(
        profile.phone, 
        message, 
        'nutrition', 
        new Types.ObjectId(profile._id.toString())
      );
      if (sent) {
        profile.lastNutritionTipSent = now;
        await profile.save();
      }

      if (profile.deficiencies?.length > 0) {
        await this.sendDeficiencyReminders(profile);
      }
    }
  }



  private async sendDeficiencyReminders(profile: NutritionProfileDocument): Promise<void> {
  for (const deficiency of profile.deficiencies) {
    const tip = DEFICIENCY_TIPS[deficiency] || deficiency;
    const deficiencyMessage = NUTRITION_MESSAGES.DEFICIENCY_REMINDER(
      profile.patientName,
      tip
    );
    await this.ensureSmsSent(
      profile.phone,
      deficiencyMessage,
      'nutrition',
      new Types.ObjectId(profile._id.toString())
    );
  }
}


  /**
   * Medication Reminder Functions
   */
  async createMedicationReminder(dto: MedicationReminderDto): Promise<Medication> {
    const medication = new this.medicationModel(dto);
    await medication.save();
    
    const confirmationMessage = `Your medication reminder for ${dto.medicationName} (${dto.dosage}) has been set up. You will receive ${dto.frequency} reminders.`;
    await this.ensureSmsSent(
      dto.phone, 
      confirmationMessage, 
      'medication', 
      new Types.ObjectId(medication._id.toString())
    );
    
    return medication;
  }

  async sendMedicationReminders(): Promise<void> {
    const now = new Date();
    
    await this.processDailyMedicationReminders(now);
    await this.processWeeklyMedicationReminders(now);
    await this.processRefillReminders(now);
  }

  private async processDailyMedicationReminders(now: Date): Promise<void> {
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
      
      const sent = await this.ensureSmsSent(
        med.phone, 
        message, 
        'medication', 
        new Types.ObjectId(med._id.toString())
      );
      if (sent) {
        med.lastReminderSent = now;
        await med.save();
      }
    }
  }

  private async processWeeklyMedicationReminders(now: Date): Promise<void> {
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
      
      const sent = await this.ensureSmsSent(
        med.phone, 
        message, 
        'medication', 
        new Types.ObjectId(med._id.toString())
      );
      if (sent) {
        med.lastReminderSent = now;
        await med.save();
      }
    }
  }

  private async processRefillReminders(now: Date): Promise<void> {
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
      
      const sent = await this.ensureSmsSent(
        med.phone, 
        message, 
        'medication', 
        new Types.ObjectId(med._id.toString())
      );
      if (sent) {
        med.lastReminderSent = now;
        await med.save();
      }
    }
  }

  async processPendingMedicationReminders(): Promise<{ sent: number; failed: number }> {
    const pendingReminders = await this.pendingReminderModel.find({ 
      type: 'medication',
      retryCount: { $lt: 5 }
    }).sort({ createdAt: 1 });

    let sentCount = 0;
    let failedCount = 0;

    for (const reminder of pendingReminders) {
      try {
        const sent = await this.sendSms(reminder.phone, reminder.message);
        
        if (sent) {
          if (reminder.referenceId) {
            await this.medicationModel.findByIdAndUpdate(reminder.referenceId, {
              lastReminderSent: new Date()
            });
          }
          await this.pendingReminderModel.findByIdAndDelete(reminder._id);
          sentCount++;
        } else {
          reminder.retryCount += 1;
          await reminder.save();
          failedCount++;
        }
      } catch (error) {
        this.logger.error(`Failed to process pending medication reminder: ${error.message}`);
        reminder.retryCount += 1;
        reminder.lastError = error.message;
        await reminder.save();
        failedCount++;
      }
    }

    return { sent: sentCount, failed: failedCount };
  }

  /**
   * Pregnancy Tracking Functions
   */
  async createPregnancyProfile(dto: PregnancyUpdateDto): Promise<Pregnancy> {
    const pregnancy = new this.pregnancyModel(dto);
    this.calculateNextAppointmentSchedule(pregnancy);
    await pregnancy.save();
    
    const welcomeMessage = `Your pregnancy profile has been created. You are currently in week ${pregnancy.currentWeek}. You will receive weekly updates about your pregnancy journey.`;
    await this.ensureSmsSent(
      dto.phone, 
      welcomeMessage, 
      'pregnancy', 
      new Types.ObjectId(pregnancy._id.toString())
    );
    
    return pregnancy;
  }

  async updatePregnancyWeek(patientId: string): Promise<Pregnancy> {
    const pregnancy = await this.pregnancyModel.findOne({ patientId });
    if (!pregnancy) {
      throw new Error('Pregnancy profile not found');
    }

    const now = new Date();
    const diffInWeeks = Math.floor((now.getTime() - pregnancy.startDate.getTime()) / (1000 * 60 * 60 * 24 * 7));
    
    if (diffInWeeks !== pregnancy.currentWeek) {
      pregnancy.currentWeek = diffInWeeks;
      this.calculateNextAppointmentSchedule(pregnancy);
      await pregnancy.save();
    }

    return pregnancy;
  }

  private calculateNextAppointmentSchedule(pregnancy: PregnancyDocument): void {
    const { currentWeek } = pregnancy;
    const nextAppointmentDate = new Date(pregnancy.startDate);
    
    if (currentWeek < PREGNANCY_STAGES.STAGE_1.end) {
      nextAppointmentDate.setDate(nextAppointmentDate.getDate() + (currentWeek + 4) * 7);
    } else if (currentWeek < PREGNANCY_STAGES.STAGE_2.end) {
      nextAppointmentDate.setDate(nextAppointmentDate.getDate() + (currentWeek + 2) * 7);
    } else {
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
      currentWeek: { $lte: 42 },
    });

    for (const pregnancy of pregnancies) {
      const weeklyUpdate = WEEKLY_UPDATES[pregnancy.currentWeek] || 
        `Your baby is growing! You're now at week ${pregnancy.currentWeek} of your pregnancy.`;
      
      const message = PREGNANCY_UPDATE_MESSAGES.WEEKLY_UPDATE(pregnancy.currentWeek, weeklyUpdate);
      
      const sent = await this.ensureSmsSent(
        pregnancy.phone, 
        message, 
        'pregnancy', 
        new Types.ObjectId(pregnancy._id.toString())
      );
      if (sent) {
        pregnancy.lastUpdateSent = now;
        await pregnancy.save();
      }

      if (pregnancy.nextAppointmentSchedule) {
        await this.sendAppointmentSchedule(pregnancy);
      }
    }
  }

  private async sendAppointmentSchedule(pregnancy: PregnancyDocument): Promise<void> {
    const scheduleMessage = PREGNANCY_UPDATE_MESSAGES.APPOINTMENT_SCHEDULE(
      `Next appointment in ${this.getAppointmentFrequency(pregnancy.currentWeek)}`
    );
    await this.ensureSmsSent(
      pregnancy.phone, 
      scheduleMessage, 
      'pregnancy', 
      new Types.ObjectId(pregnancy._id.toString())
    );
  }

  private getAppointmentFrequency(currentWeek: number): string {
    if (currentWeek < PREGNANCY_STAGES.STAGE_1.end) {
      return '4 weeks (monthly)';
    } else if (currentWeek < PREGNANCY_STAGES.STAGE_2.end) {
      return '2 weeks (twice monthly)';
    }
    return '1 week (weekly)';
  }

  /**
   * General SMS Functions
   */
  async testSms(phone: string): Promise<boolean> {
    const testMessage = "This is a test message from your healthcare provider's system.";
    return this.ensureSmsSent(phone, testMessage);
  }

  async processPendingReminders(): Promise<{ sent: number; failed: number }> {
    const pendingReminders = await this.pendingReminderModel.find({ 
      retryCount: { $lt: 5 }
    }).sort({ createdAt: 1 });

    let sentCount = 0;
    let failedCount = 0;

    for (const reminder of pendingReminders) {
      try {
        const sent = await this.sendSms(reminder.phone, reminder.message);
        
        if (sent) {
          await this.updateReferenceRecord(reminder);
          await this.pendingReminderModel.findByIdAndDelete(reminder._id);
          sentCount++;
        } else {
          await this.incrementRetryCount(reminder);
          failedCount++;
        }
      } catch (error) {
        await this.handlePendingReminderError(reminder, error);
        failedCount++;
      }
    }

    return { sent: sentCount, failed: failedCount };
  }

  /**
   * Helper Methods
   */
  private formatPhoneNumber(phone: string): string {
    let formatted = phone.trim();
    if (formatted.startsWith('+')) formatted = formatted.substring(1);
    if (formatted.startsWith('0')) formatted = '233' + formatted.substring(1);
    return formatted;
  }

  private async createSmsRecord(phone: string, message: string): Promise<SmsRecordDocument> {
    return this.smsModel.create({
      phone,
      message,
      // Changed from 'outbound' to 'OUTBOUND' to match your schema's enum values
      type: 'OUTBOUND',
      status: 'pending',
    });
  }

  private async handleSmsError(
    error: any,
    smsRecord: SmsRecordDocument,
    phone: string,
    message: string
  ): Promise<void> {
    smsRecord.status = 'failed';
    
    if (error.response) {
      smsRecord.failureReason = `Status ${error.response.status}: ${JSON.stringify(error.response.data)}`;
    } else {
      smsRecord.failureReason = error.message;
    }
    
    await smsRecord.save();
   this.logger.error(`Failed to send SMS to ${phone}: ${error.response?.data?.message || error.message}`);

  }

  private async ensureSmsSent(
    phone: string,
    message: string,
    type?: string,
    referenceId?: Types.ObjectId
  ): Promise<boolean> {
    try {
      const sent = await this.sendSms(phone, message);
      if (!sent) {
        await this.storePendingReminder(phone, message, type, referenceId);
      }
      return sent;
    } catch (error) {
      await this.storePendingReminder(phone, message, type, referenceId);
      return false;
    }
  }

  private async storePendingReminder(
    phone: string, 
    message: string, 
    type?: string, 
    referenceId?: Types.ObjectId
  ): Promise<PendingReminderDocument> {
    return this.pendingReminderModel.create({
      phone,
      message,
      type,
      referenceId,
      createdAt: new Date(),
      retryCount: 0,
    });
  }

  private async processAppointmentReminders(
    endDate: Date,
    now: Date,
    reminderType: string,
    messageBuilder: (details: any) => string
  ): Promise<void> {
    const appointments = await this.appointmentModel.find({
      date: { $lte: endDate, $gte: now },
      [`reminders.${reminderType}`]: false,
    });

    for (const appointment of appointments) {
      const message = messageBuilder({
        date: appointment.date,
        doctor: appointment.doctor,
        location: appointment.location
      });
      
      const sent = await this.ensureSmsSent(
        appointment.phone, 
        message, 
        'appointment', 
        new Types.ObjectId(appointment._id.toString())
      );
      if (sent) {
        appointment.reminders[reminderType] = true;
        await appointment.save();
      }
    }
  }

  private async updateReferenceRecord(reminder: PendingReminderDocument): Promise<void> {
    if (!reminder.referenceId) return;

    switch (reminder.type) {
      case 'appointment':
        await this.updateAppointmentReminderStatus(reminder);
        break;
      case 'medication':
        await this.medicationModel.findByIdAndUpdate(reminder.referenceId, {
          lastReminderSent: new Date()
        });
        break;
      case 'nutrition':
        await this.updateNutritionReminderStatus(reminder);
        break;
      case 'pregnancy':
        await this.pregnancyModel.findByIdAndUpdate(reminder.referenceId, {
          lastUpdateSent: new Date()
        });
        break;
    }
  }

  private async updateAppointmentReminderStatus(reminder: PendingReminderDocument): Promise<void> {
    const update: any = {};
    if (reminder.message.includes('week before')) {
      update['reminders.weekBefore'] = true;
    } else if (reminder.message.includes('two days before')) {
      update['reminders.twoDaysBefore'] = true;
    } else if (reminder.message.includes('day before')) {
      update['reminders.dayBefore'] = true;
    }

    if (Object.keys(update).length > 0) {
      await this.appointmentModel.findByIdAndUpdate(reminder.referenceId, update);
    }
  }

  private async updateNutritionReminderStatus(reminder: PendingReminderDocument): Promise<void> {
    const update = reminder.message.includes('water intake') 
      ? { lastWaterReminderSent: new Date() }
      : { lastNutritionTipSent: new Date() };

    await this.nutritionModel.findByIdAndUpdate(reminder.referenceId, update);
  }

  private async incrementRetryCount(reminder: PendingReminderDocument): Promise<void> {
    reminder.retryCount += 1;
    await reminder.save();
  }

  private async handlePendingReminderError(
    reminder: PendingReminderDocument,
    error: any
  ): Promise<void> {
    this.logger.error(`Failed to process pending reminder: ${error.message}`);
    reminder.retryCount += 1;
    reminder.lastError = error.message;
    await reminder.save();
  }
}