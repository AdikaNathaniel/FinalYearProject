// vital.dto.ts

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
}
