// src/notification/notification.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Notification } from 'src/shared/schema/notification.schema';
import { CreateNotificationDto } from  'src/users/dto/create-notification.dto';
import { UpdateNotificationDto } from 'src/users/dto/update-notification.dto';
import { SmsNotificationService } from './sms-notification.service';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectModel(Notification.name)
    private notificationModel: Model<Notification>,
    private readonly smsService: SmsNotificationService,
  ) {}

  async create(createNotificationDto: CreateNotificationDto): Promise<Notification> {
    const createdNotification = new this.notificationModel(createNotificationDto);
    const savedNotification = await createdNotification.save();

    const now = new Date();
    const scheduledTime = new Date(createNotificationDto.scheduledAt);

    if (scheduledTime <= now) {
      this.logger.log('Sending immediate notification');
      await this.smsService.sendSms(savedNotification);
      await this.markAsSent(savedNotification._id.toString());
    } else {
      this.logger.log(`Scheduling notification for ${scheduledTime}`);
      await this.smsService.sendScheduledSms(savedNotification);
    }

    return savedNotification;
  }

  async findAll(): Promise<Notification[]> {
    return this.notificationModel.find().exec();
  }

  async findOne(id: string): Promise<Notification> {
    return this.notificationModel.findById(id).exec();
  }

  async findByRole(role: string): Promise<Notification[]> {
    return this.notificationModel.find({ role }).exec();
  }

  async update(
    id: string,
    updateNotificationDto: UpdateNotificationDto,
  ): Promise<Notification> {
    return this.notificationModel
      .findByIdAndUpdate(id, updateNotificationDto, { new: true })
      .exec();
  }

  async remove(id: string): Promise<Notification> {
    return this.notificationModel.findByIdAndDelete(id).exec();
  }

  async markAsSent(id: string): Promise<Notification> {
    return this.notificationModel
      .findByIdAndUpdate(
        id,
        { isSent: true, sentAt: new Date() },
        { new: true },
      )
      .exec();
  }

  async markAsRead(id: string): Promise<Notification> {
    return this.notificationModel
      .findByIdAndUpdate(
        id,
        { isRead: true, readAt: new Date() },
        { new: true },
      )
      .exec();
  }

  async getPendingNotifications(): Promise<Notification[]> {
    const now = new Date();
    return this.notificationModel
      .find({ isSent: false, scheduledAt: { $lte: now } })
      .exec();
  }
}