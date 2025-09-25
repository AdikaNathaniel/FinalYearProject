import { IsNotEmpty } from "class-validator";

export class RiskResultDto {
  probability: number;
  riskClass: string;
  rawScore: number;
  featureContributions: Record<string, number>;
  bmiValue: number;
  encodedAge: number;
  patientId: string;
}