export class VitalDto {
  id: string;
  patientId: string;
  systolic: number;
  diastolic: number;
  map: number;
  proteinuria: number;
  temperature: number;
  heartRate: number;
  spo2: number;
  severity: string;
  rationale?: string;
  createdAt: Date;
  mlSeverity?: string;
  mlProbability?: Record<string, number>;
}