import { Injectable, OnModuleInit } from '@nestjs/common';
import { SchedulerRegistry } from '@nestjs/schedule';
import { CronJob } from 'cron';
import { SmsService } from './sms.service';

@Injectable()
export class SmsScheduler implements OnModuleInit {
  constructor(
    private readonly schedulerRegistry: SchedulerRegistry,
    private readonly smsService: SmsService,
  ) {}

  // cWZPeGl3anVMTXFheHRTb3F5QkE

  onModuleInit() {
    // Schedule appointment reminders to run every hour
    const appointmentJob = new CronJob('0 * * * *', () => {
      this.smsService.sendAppointmentReminders();
    });
    this.schedulerRegistry.addCronJob('appointmentReminders', appointmentJob);
    appointmentJob.start();

    // Schedule water intake reminders to run daily at 9am
    const waterJob = new CronJob('0 9 * * *', () => {
      this.smsService.sendWaterIntakeReminders();
    });
    this.schedulerRegistry.addCronJob('waterIntakeReminders', waterJob);
    waterJob.start();

    // Schedule nutrition tips to run every 3 days at 10am
    const nutritionJob = new CronJob('0 10 */3 * *', () => {
      this.smsService.sendNutritionTips();
    });
    this.schedulerRegistry.addCronJob('nutritionTips', nutritionJob);
    nutritionJob.start();

    // Schedule medication reminders to run daily at 8am
    const medicationJob = new CronJob('0 8 * * *', () => {
      this.smsService.sendMedicationReminders();
    });
    this.schedulerRegistry.addCronJob('medicationReminders', medicationJob);
    medicationJob.start();

    // Schedule pregnancy updates to run weekly on Monday at 11am
    const pregnancyJob = new CronJob('0 11 * * 1', () => {
      this.smsService.sendWeeklyPregnancyUpdates();
    });
    this.schedulerRegistry.addCronJob('pregnancyUpdates', pregnancyJob);
    pregnancyJob.start();
  }
}