import { IsNotEmpty, IsString, IsNumber, IsArray } from 'class-validator';

export class NutritionReminderDto {
  @IsNotEmpty()
  @IsString()
  phone: string;

  @IsNotEmpty()
  @IsString()
  patientName: string;

  @IsNotEmpty()
  @IsNumber()
  trimester: number;

  @IsNotEmpty()
  @IsNumber()
  waterIntakeGoal: number;

  @IsArray()
  @IsString({ each: true })
  deficiencies: string[];
}