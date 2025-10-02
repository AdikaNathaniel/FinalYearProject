import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class RiskAssessment extends Document {
  @Prop({ required: true })
  patientId: string;

  // Change from boolean to number (0 or 1)
  @Prop({ required: true, type: Number })
  excessiveVomiting: number;

  @Prop({ required: true, type: Number })
  diarrhea: number;

  @Prop({ required: true, type: Number })
  historyHeavyMenstrualFlow: number;

  @Prop({ required: true, type: Number })
  infections: number;

  @Prop({ required: true, type: Number })
  chronicDisease: number;

  @Prop({ required: true, type: Number })
  familyHistory: number;

  // Rename from 'bmi' to 'bmiLow' and change type
  @Prop({ required: true, type: Number })
  bmiLow: number; // 0 or 1 (encoded)

  // Add this new field to store the actual BMI value
  @Prop({ required: true, type: Number })
  bmiValue: number;

  @Prop({ required: true, type: Number })
  shortInterpregnancyInterval: number;

  @Prop({ required: true, type: Number })
  multiplePregnancy: number;

  // Rename from 'age' to 'age35OrLess' and change type
  @Prop({ required: true, type: Number })
  age35OrLess: number; // 0 or 1 (encoded)

  @Prop({ required: true, type: Number })
  poverty: number;

  @Prop({ required: true, type: Number })
  lackOfAccessHealthcare: number;

  @Prop({ required: true, type: Number })
  education: number;

  @Prop({ required: true })
  calculatedRisk: number;

  @Prop({ required: true })
  riskClass: string;

  @Prop({ required: true, default: Date.now })
  createdAt: Date;

  // Add updatedAt field
  @Prop({ default: Date.now })
  updatedAt: Date;


  @Prop({ type: Object })
featureContributions: Record<string, {
  input: number;
  weight: number;
  contribution: number;
}>;

@Prop({ required: true })
rawScore: number;

@Prop({ required: true })
encodedAge: number

}

export const RiskAssessmentSchema = SchemaFactory.createForClass(RiskAssessment);