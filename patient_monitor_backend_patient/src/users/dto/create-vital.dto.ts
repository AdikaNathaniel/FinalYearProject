export class CreateVitalDto {
  patientId: string;
  systolic: number;
  diastolic: number;
  proteinuria: number;
  temperature: number;
  heartRate: number;
  spo2: number;
  severity: string;
  rationale?: string;
}