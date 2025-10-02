import { IsNotEmpty, IsDateString, IsNumber, IsOptional } from 'class-validator';
import { Transform } from 'class-transformer';

export class CreatePrescriptionDto {
  @IsNotEmpty()
  patient_name: string;

  @IsNotEmpty()
  drug_name: string;

  @IsNotEmpty()
  dosage: string;

  @IsNotEmpty()
  route_of_administration: string;

  @IsNotEmpty()
  frequency: string;

  @IsNotEmpty()
  duration: string;

  @IsNotEmpty()
  @IsDateString()  // ✅ Changed from @IsDate() to @IsDateString()
  start_date: string;

  @IsNotEmpty()
  @IsDateString()  // ✅ Changed from @IsDate() to @IsDateString()
  end_date: string;

  @IsNotEmpty()
  @Transform(({ value }) => parseInt(value))  // ✅ Added transform for string to number
  @IsNumber()
  quantity: number;

  @IsOptional()  // ✅ Added @IsOptional() for optional fields
  reason?: string;

  @IsOptional()  // ✅ Added @IsOptional() for optional fields
  notes?: string;
}