// create-vital.dto.ts
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
}