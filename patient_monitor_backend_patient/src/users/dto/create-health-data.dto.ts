import { IsString, IsNumber, IsBoolean, Min, Max } from 'class-validator';

export class CreateHealthDataDto {
  @IsString()
  patient_name: string;

  @IsNumber()
  @Min(1)
  @Max(50)
  gestational_week: number;

  @IsNumber()
  @Min(30)
  @Max(45)
  temperature: number;

  @IsNumber()
  @Min(80)
  @Max(200)
  systolic_bp: number;

  @IsNumber()
  @Min(50)
  @Max(120)
  diastolic_bp: number;

  @IsNumber()
  @Min(50)
  @Max(300)
  glucose: number;

  @IsNumber()
  @Min(80)
  @Max(100)
  spo2: number;

  @IsNumber()
  @Min(40)
  @Max(150)
  heart_rate: number;

  @IsNumber()
  @Min(15)
  @Max(50)
  bmi: number;

  @IsBoolean()
  preeclampsia_risk: boolean;

  @IsBoolean()
  anemia_risk: boolean;

  @IsBoolean()
  gdm_risk: boolean;
}