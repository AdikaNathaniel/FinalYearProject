export class CreateChartDataDto {
  glucose: number;
  systolicBP: number;
  diastolicBP: number;
  heartRate: number;
  spo2: number;
  skinTemp: number;
  bodyTemp: number;
  accelX: number;
  accelY: number;
  accelZ: number;
  gyroX: number;
  gyroY: number;
  gyroZ: number;
  proteinLevel?: number;
  createdAt: Date;
  updatedAt: Date;
}
