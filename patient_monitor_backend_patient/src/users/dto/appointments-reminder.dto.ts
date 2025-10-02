// src/users/dto/appointment-reminder.dto.ts
import { IsString, IsDateString, IsOptional, IsMongoId } from 'class-validator';
import { Types } from 'mongoose';

export class AppointmentReminderDto {
  @IsString()
  patientName: string;

  @IsString()
  phone: string;

//   @IsString()
//   doctor: string;
  

   @IsString()
   doctor: string;

  @IsDateString()
  date: string;

  @IsString()
  @IsOptional()
  purpose?: string;

  @IsString()
  @IsOptional()
  location?: string;
}