import { 
  IsString, 
  IsNumber, 
  IsNotEmpty, 
  Min, 
  Max, 
  IsPositive 
} from 'class-validator';

export class CreatePatientHardwareDto {
  @IsString()
  @IsNotEmpty()
  patient_name: string;

  @IsNumber()
  @Min(1)
  @Max(42)
  gestational_week: number;

  @IsNumber()
  @IsPositive()
  temperature: number;

  @IsNumber()
  @IsPositive()
  systolic_bp: number;

  @IsNumber()
  @IsPositive()
  diastolic_bp: number;

  @IsNumber()
  @IsPositive()
  glucose: number;

  @IsNumber()
  @Min(0)
  @Max(100)
  spo2: number;

  @IsNumber()
  @IsPositive()
  heart_rate: number;

  @IsNumber()
  @IsPositive()
  bmi: number;
}