import { IsDate, IsNumber, IsNotEmpty, IsString } from 'class-validator';

export class PregnancyUpdateDto {
  @IsNotEmpty()
  @IsString()
  patientId: string;

  @IsNotEmpty()
  @IsString()
  phone: string;

  @IsNotEmpty()
  @IsDate()
  startDate: Date;

  @IsNotEmpty()
  @IsNumber()
  currentWeek: number;
}