// // vital.dto.ts

// import { Expose } from 'class-transformer';

// export class VitalDto {
//   @Expose() id: string;
//   @Expose() patientId: string;
//   @Expose() systolic: number;
//   @Expose() diastolic: number;
//   @Expose() map: number;
//   @Expose() proteinuria: number;
//   @Expose() glucose: number;
//   @Expose() temperature: number;
//   @Expose() heartRate: number;
//   @Expose() spo2: number;
//   @Expose() severity: string;
//   @Expose() rationale?: string;
//   @Expose() createdAt: Date;
//   @Expose() mlSeverity?: string;
//   @Expose() mlProbability?: Record<string, number>;
// }




import { Expose } from 'class-transformer';

export class VitalDto {
  @Expose() id: string;
  @Expose() patientId: string;
  @Expose() systolic: number;
  @Expose() diastolic: number;
  @Expose() map: number;
  @Expose() proteinuria: number;
  @Expose() glucose: number;
  @Expose() temperature: number;
  @Expose() heartRate: number;
  @Expose() spo2: number;
  @Expose() severity: string;
  @Expose() rationale?: string;
  @Expose() createdAt: Date;
  @Expose() mlSeverity?: string;
  @Expose() mlProbability?: Record<string, number>;

  // Alert fields
  @Expose() hasAlerts?: boolean;
  @Expose() tempAlert?: boolean;
  @Expose() hrAlert?: boolean;
  @Expose() spo2Alert?: boolean;
  @Expose() glucoseAlert?: boolean;
  @Expose() tempAlertSeverity?: 'LOW' | 'HIGH';
  @Expose() hrAlertSeverity?: 'LOW' | 'HIGH';
  @Expose() spo2AlertSeverity?: 'LOW' | 'HIGH';
  @Expose() glucoseAlertSeverity?: 'LOW' | 'HIGH';
  @Expose() thresholds?: {
    tempLow?: number;
    tempHigh?: number;
    hrLow?: number;
    hrHigh?: number;
    spo2Low?: number;
    spo2High?: number;
    glucoseLow?: number;
    glucoseHigh?: number;
  };
}
