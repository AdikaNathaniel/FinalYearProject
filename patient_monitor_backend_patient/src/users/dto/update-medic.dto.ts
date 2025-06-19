import { PartialType } from '@nestjs/mapped-types';
import { CreateMedicDto, ConsultationHoursDto } from './create-medic.dto';
import { IsString, IsArray, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateMedicDto extends PartialType(CreateMedicDto) {
  @IsString()
  @IsOptional()
  fullName?: string;

  @IsString()
  @IsOptional()
  hospital?: string;

  @IsString()
  @IsOptional()
  profilePhoto?: string;

  @IsString()
  @IsOptional()
  specialization?: string;

  @IsString()
  @IsOptional()
  yearsOfPractice?: string;

  @ValidateNested()
  @Type(() => ConsultationHoursDto)
  @IsOptional()
  consultationHours?: ConsultationHoursDto | string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  languagesSpoken?: string[] | string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @IsString()
  @IsOptional()
  consultationFee?: string;
}