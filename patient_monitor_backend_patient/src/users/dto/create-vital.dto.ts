// // create-vital.dto.ts
// export class CreateVitalDto {
//   patientId: string;
//   systolic: number;
//   diastolic: number;
//   map?: number;
//   proteinuria: number;
//   glucose: number;
//   temperature: number;
//   heartRate: number;
//   spo2: number;
//   severity: string;
//   rationale: string;
//   mlSeverity?: string;
//   mlProbability?: Record<string, number>;
//   timestamp?: Date;
// }



export class CreateVitalDto {
  patientId: string;
  systolic: number;
  diastolic: number;
  map?: number;
  proteinuria: number;
  glucose: number;
  temperature: number;
  heartRate: number;
  spo2: number;
  severity: string;
  rationale: string;
  mlSeverity?: string;
  mlProbability?: Record<string, number>;
  timestamp?: Date;

  // Alert fields
  hasAlerts?: boolean;
  tempAlert?: boolean;
  hrAlert?: boolean;
  spo2Alert?: boolean;
  glucoseAlert?: boolean;
  
  // Alert severity levels
  tempAlertSeverity?: 'LOW' | 'HIGH';
  hrAlertSeverity?: 'LOW' | 'HIGH';
  spo2AlertSeverity?: 'LOW' | 'HIGH';
  glucoseAlertSeverity?: 'LOW' | 'HIGH';
  
  // Threshold values
  thresholds?: {
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