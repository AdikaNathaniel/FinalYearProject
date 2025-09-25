import { IsOptional, IsString, IsDate, IsObject, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class PharmacyDto {
  @IsString()
  name: string;

  @IsString()
  phone: string;
}

export class MedicationReminderDto {
  @IsString()
  phone: string;

  @IsString()
  patientName: string;

  @IsString()
  medicationName: string;

  @IsString()
  dosage: string;

  @IsString()
  frequency: string;

  @IsString()
  time: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  refillDate?: Date;

  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PharmacyDto)
  pharmacy?: PharmacyDto;
}