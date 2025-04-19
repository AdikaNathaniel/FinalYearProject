import { IsNotEmpty, IsDate, IsNumber } from 'class-validator';

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
  @IsDate()
  start_date: string;

  @IsNotEmpty()
  @IsDate()
  end_date: string;

  @IsNotEmpty()
  @IsNumber()
  quantity: number;

  reason?: string;

  notes?: string;
}
