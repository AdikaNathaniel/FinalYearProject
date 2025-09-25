import { IsNotEmpty, IsOptional, IsNumber, IsString } from 'class-validator';

export class CreateReportDto {
  @IsNumber()
  @IsNotEmpty()
  body_temperature: number;

  @IsNumber()
  @IsNotEmpty()
  heart_rate: number;

  @IsNumber()
  @IsNotEmpty()
  oxygen_saturation: number;

  @IsString()
  @IsNotEmpty()
  blood_pressure: string;

  @IsNumber()
  @IsNotEmpty()
  blood_glucose: number;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  drugs?: string;
}