import { IsOptional, IsNotEmpty, IsDate, IsNumber } from 'class-validator';

export class UpdatePrescriptionDto {
  @IsOptional()
  @IsNotEmpty()
  patient_name?: string;

  @IsOptional()
  @IsNotEmpty()
  drug_name?: string;

  @IsOptional()
  @IsNotEmpty()
  dosage?: string;

  @IsOptional()
  @IsNotEmpty()
  route_of_administration?: string;

  @IsOptional()
  @IsNotEmpty()
  frequency?: string;

  @IsOptional()
  @IsNotEmpty()
  duration?: string;

  @IsOptional()
  @IsDate()
  start_date?: string;

  @IsOptional()
  @IsDate()
  end_date?: string;

  @IsOptional()
  @IsNumber()
  quantity?: number;

  @IsOptional()
  reason?: string;

  @IsOptional()
  notes?: string;
}
