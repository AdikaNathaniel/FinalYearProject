import { IsString, IsArray, IsNotEmpty, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class ConsultationHoursDto {
  @IsArray()
  @IsString({ each: true })
  days: string[];

  @IsString()
  @IsNotEmpty()
  startTime: string;

  @IsString()
  @IsNotEmpty()
  endTime: string;
}

export class CreateMedicDto {
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @IsString()
  @IsOptional()
  hospital?: string;

  @IsString()
  @IsOptional()
  profilePhoto?: string;

  @IsString()
  @IsNotEmpty()
  specialization: string;

  @IsString()
  @IsNotEmpty()
  yearsOfPractice: string;

  @ValidateNested()
  @Type(() => ConsultationHoursDto)
  consultationHours: ConsultationHoursDto | string;

  @IsArray()
  @IsString({ each: true })
  languagesSpoken: string[] | string;

  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  consultationFee: string;
}