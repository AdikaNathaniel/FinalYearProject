import { IsNumber, IsString, Min, Max } from 'class-validator';

export class CreatePreeclampsiaVitalsDto {
  @IsString()
  patientId: string;

  @IsNumber()
  @Min(70)
  @Max(300)
  systolicBP: number;

  @IsNumber()
  @Min(40)
  @Max(200)
  diastolicBP: number;

  @IsNumber()
  @Min(0)
  @Max(4)
  proteinUrine: number;
}