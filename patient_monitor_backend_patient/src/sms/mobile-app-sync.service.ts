
import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  OfflineReminder,
  OfflineReminderDocument,
} from 'src/shared/schema/offline-reminder.schema';

@Injectable()
export class MobileAppSyncService {
  private readonly logger = new Logger(MobileAppSyncService.name);
  private readonly apiBaseUrl: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    @InjectModel(OfflineReminder.name)
    private readonly offlineReminderModel: Model<OfflineReminderDocument>,
  ) {
    this.apiBaseUrl = this.configService.get<string>('API_BASE_URL') || 'http://localhost:3100';
  }

  /**
   * Stores medication reminders locally when offline
   */
  async storeOfflineMedicationReminder(payload: any): Promise<OfflineReminder> {
    const reminder = new this.offlineReminderModel({
      type: 'medication',
      payload,
      createdAt: new Date(),
      synced: false,
      retryCount: 0,
    });
    
    return reminder.save();
  }

  /**
   * Syncs all offline stored medication reminders when connectivity is restored
   */
  async syncOfflineMedicationReminders(): Promise<{ success: number; failed: number }> {
    const pendingReminders = await this.offlineReminderModel.find({
      synced: false,
      retryCount: { $lt: 5 },
    });

    let successCount = 0;
    let failedCount = 0;

    for (const reminder of pendingReminders) {
      try {
        await firstValueFrom(
          this.httpService.post(`${this.apiBaseUrl}/medication-reminders`, reminder.payload)
        );
        
        reminder.synced = true;
        await reminder.save();
        successCount++;
      } catch (error) {
        this.logger.error(`Failed to sync offline reminder: ${error.message}`);
        reminder.retryCount += 1;
        reminder.lastError = error.message;
        await reminder.save();
        failedCount++;
      }
    }

    return { success: successCount, failed: failedCount };
  }

  /**
   * Triggers sending of pending reminders
   */
  async triggerPendingReminders(): Promise<boolean> {
    try {
      await firstValueFrom(
        this.httpService.post(`${this.apiBaseUrl}/medication-reminders/send-pending`)
      );
      return true;
    } catch (error) {
      this.logger.error(`Failed to trigger pending reminders: ${error.message}`);
      return false;
    }
  }

  /**
   * Check connectivity and trigger sync if online
   */
  async checkConnectivityAndSync(): Promise<boolean> {
    try {
      const connectivityEndpoint = 'https://www.google.com';
      await firstValueFrom(
        this.httpService.get(connectivityEndpoint, { timeout: 5000, responseType: 'text' })
      );
      
      // We're online, sync offline reminders
      await this.syncOfflineMedicationReminders();
      
      // Trigger sending of pending reminders
      await this.triggerPendingReminders();
      
      return true;
    } catch (error) {
      this.logger.warn('No internet connection available for sync');
      return false;
    }
  }
}