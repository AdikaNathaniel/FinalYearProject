import { IsBoolean, IsNumber, IsNotEmpty, IsString } from 'class-validator';

export class PredictRiskDto {


  @IsNotEmpty()
  @IsString()
  patientId: string;
  
  @IsBoolean()
  excessiveVomiting: boolean;

  @IsBoolean()
  diarrhea: boolean;

  @IsBoolean()
  historyHeavyMenstrualFlow: boolean;

  @IsBoolean()
  infections: boolean;

  @IsBoolean()
  chronicDisease: boolean;

  @IsBoolean()
  familyHistory: boolean;

  @IsNumber()
  @IsNotEmpty()
  weight: number; // in kg

  @IsNumber()
  @IsNotEmpty()
  height: number; // in meters

  @IsNumber()
  @IsNotEmpty()
  age: number; // in years

  @IsBoolean()
  shortInterpregnancyInterval: boolean;

  @IsBoolean()
  multiplePregnancy: boolean;

  @IsBoolean()
  poverty: boolean;

  @IsBoolean()
  lackOfAccessHealthcare: boolean;

  @IsBoolean()
  education: boolean;
}