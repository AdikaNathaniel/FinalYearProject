// src/notification/notification.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Put,
  Delete,
  Query,
} from '@nestjs/common';
import { NotificationService } from './notification.service';
import { CreateNotificationDto } from  'src/users/dto/create-notification.dto';
import { UpdateNotificationDto } from 'src/users/dto/update-notification.dto';
import { NotificationRole } from 'src/shared/schema/notification.schema';

@Controller('notifications')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post()
  create(@Body() createNotificationDto: CreateNotificationDto) {
    return this.notificationService.create(createNotificationDto);
  }

  @Get()
  findAll() {
    return this.notificationService.findAll();
  }

  @Get('role/:role')
  findByRole(@Param('role') role: NotificationRole) {
    return this.notificationService.findByRole(role);
  }

  @Get('pending')
  getPendingNotifications() {
    return this.notificationService.getPendingNotifications();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.notificationService.findOne(id);
  }

  @Put(':id')
  update(
    @Param('id') id: string,
    @Body() updateNotificationDto: UpdateNotificationDto,
  ) {
    return this.notificationService.update(id, updateNotificationDto);
  }

  @Put(':id/mark-as-sent')
  markAsSent(@Param('id') id: string) {
    return this.notificationService.markAsSent(id);
  }

  @Put(':id/mark-as-read')
  markAsRead(@Param('id') id: string) {
    return this.notificationService.markAsRead(id);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.notificationService.remove(id);
  }
}