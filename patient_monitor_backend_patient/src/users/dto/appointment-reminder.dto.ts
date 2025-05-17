import { IsDate, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';


export class AppointmentReminderDto {

  @IsNotEmpty()
  @IsString()
  patientName: string;

  @IsNotEmpty()
  @IsString()
  doctor: string;

   @IsNotEmpty()
  @IsString()
  purpose: string;

  @IsNotEmpty()
  @IsString()
  patientId: string;

  @IsNotEmpty()
  @IsString()
  phone: string;

  @IsNotEmpty()
  @Type(() => Date) 
  @IsDate()
  date: Date;

  
  // @IsString()
  // doctor: string;

  @IsNotEmpty()
  @IsString()
  location: string;

  @IsOptional()
  @IsString()
  specialInstructions?: string;
}