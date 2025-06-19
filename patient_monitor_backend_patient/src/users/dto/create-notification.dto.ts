// src/notification/dto/create-notification.dto.ts
import { IsString, IsNotEmpty, IsDateString } from 'class-validator';

export class CreateNotificationDto {
  @IsString()
  @IsNotEmpty()
  role: string;  // 

  @IsString()
  @IsNotEmpty()
  message: string;

  @IsDateString()
  scheduledAt: string; 
}
