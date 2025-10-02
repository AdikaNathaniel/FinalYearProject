import { IsNumber, IsOptional } from 'class-validator';

export class CreateHeltecLiveVitalsDto {
  @IsNumber() glucose: number;
  @IsNumber() systolicBP: number;
  @IsNumber() diastolicBP: number;
  @IsNumber() heartRate: number;
  @IsNumber() spo2: number;
  @IsNumber() skinTemp: number;
  @IsNumber() bodyTemp: number;
  @IsNumber() accelX: number;
  @IsNumber() accelY: number;
  @IsNumber() accelZ: number;
  @IsNumber() gyroX: number;
  @IsNumber() gyroY: number;
  @IsNumber() gyroZ: number;

  @IsOptional()
  @IsNumber()
  proteinLevel?: number;
}


