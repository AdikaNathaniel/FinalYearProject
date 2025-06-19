import { Injectable, OnModuleInit, Logger, OnApplicationShutdown } from '@nestjs/common';
import { SchedulerRegistry } from '@nestjs/schedule';
import { CronJob } from 'cron';
import { SmsService } from './sms.service';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SmsScheduler implements OnModuleInit, OnApplicationShutdown {
  private readonly logger = new Logger(SmsScheduler.name);
  private isConnected = false;
  private connectionCheckInterval: NodeJS.Timeout;

  constructor(
    private readonly schedulerRegistry: SchedulerRegistry,
    private readonly smsService: SmsService,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {}

  async onModuleInit() {
    try {
      this.startConnectivityChecker();

      // Schedule all jobs
      this.scheduleJob('0 * * * *', 'appointmentReminders', () => {
        this.smsService.sendAppointmentReminders().catch(error => {
          this.logger.error(`Error in appointment reminders: ${error.message}`);
        });
      });

      this.scheduleJob('0 9 * * *', 'waterIntakeReminders', () => {
        this.smsService.sendWaterIntakeReminders().catch(error => {
          this.logger.error(`Error in water intake reminders: ${error.message}`);
        });
      });

      this.scheduleJob('0 10 */3 * *', 'nutritionTips', () => {
        this.smsService.sendNutritionTips().catch(error => {
          this.logger.error(`Error in nutrition tips: ${error.message}`);
        });
      });

      this.scheduleJob('0 8 * * *', 'medicationReminders', () => {
        this.smsService.sendMedicationReminders().catch(error => {
          this.logger.error(`Error in medication reminders: ${error.message}`);
        });
      });

      this.scheduleJob('0 11 * * 1', 'pregnancyUpdates', () => {
        this.smsService.sendWeeklyPregnancyUpdates().catch(error => {
          this.logger.error(`Error in pregnancy updates: ${error.message}`);
        });
      });

      this.scheduleJob('*/15 * * * *', 'pendingRemindersProcessor', async () => {
        try {
          const result = await this.smsService.processPendingReminders();
          this.logger.log(`Processed pending reminders: ${result.sent} sent, ${result.failed} failed`);
        } catch (error) {
          this.logger.error(`Error processing pending reminders: ${error.message}`);
        }
      });

      // Process any pending reminders on startup if connected
      if (this.isConnected) {
        try {
          const result = await this.smsService.processPendingReminders();
          this.logger.log(`Initial pending reminders processed: ${result.sent} sent, ${result.failed} failed`);
        } catch (error) {
          this.logger.error(`Error processing initial pending reminders: ${error.message}`);
        }
      }
    } catch (error) {
      this.logger.error(`Failed to initialize scheduler: ${error.message}`);
      throw error;
    }
  }

  private scheduleJob(cronTime: string, name: string, callback: () => void | Promise<void>) {
    try {
      // Check if job already exists
      if (this.schedulerRegistry.doesExist('cron', name)) {
        this.logger.warn(`Cron job ${name} already exists. Skipping registration.`);
        return;
      }

      const job = new CronJob(
        cronTime,
        () => {
          if (this.isConnected) {
            callback();
          } else {
            this.logger.warn(`Skipping ${name} due to no internet connection`);
          }
        },
        null, // onComplete
        false, // start
        'UTC' // timeZone
      );

      this.schedulerRegistry.addCronJob(name, job as any);
      job.start();
      this.logger.log(`Successfully scheduled ${name} to run at ${cronTime}`);
    } catch (error) {
      this.logger.error(`Failed to schedule job ${name}: ${error.message}`);
    }
  }

  private startConnectivityChecker() {
    // Initial check
    this.checkInternetConnectivity().catch(error => {
      this.logger.error(`Initial connectivity check failed: ${error.message}`);
    });

    // Periodic checks
    this.connectionCheckInterval = setInterval(() => {
      this.checkInternetConnectivity().catch(error => {
        this.logger.error(`Periodic connectivity check failed: ${error.message}`);
      });
    }, 60000); // Check every minute
  }

  private async checkInternetConnectivity() {
    try {
      const connectivityEndpoint = this.configService.get<string>('CONNECTIVITY_CHECK_URL') || 
                                'https://www.google.com';
      
      await firstValueFrom(
        this.httpService.get(connectivityEndpoint, { 
          timeout: 5000,
          responseType: 'text'
        })
      );
      
      const wasConnected = this.isConnected;
      this.isConnected = true;
      
      if (!wasConnected) {
        this.logger.log('Internet connection restored');
        try {
          await this.smsService.processPendingReminders();
        } catch (error) {
          this.logger.error(`Failed to process pending reminders after reconnection: ${error.message}`);
        }
      }
    } catch (error) {
      this.isConnected = false;
      this.logger.warn('No internet connection available');
    }
  }

  onApplicationShutdown() {
    this.logger.log('Shutting down scheduler...');
    clearInterval(this.connectionCheckInterval);
    
    // Clean up all cron jobs
    const jobs = this.schedulerRegistry.getCronJobs();
    jobs.forEach((job, name) => {
      job.stop();
      this.schedulerRegistry.deleteCronJob(name);
      this.logger.log(`Stopped and removed cron job: ${name}`);
    });
  }
}