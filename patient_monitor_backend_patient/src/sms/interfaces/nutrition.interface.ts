export interface NutritionProfile {
    patientId: string;
    phone: string;
    trimester: 1 | 2 | 3;
    deficiencies: string[];
    waterIntakeGoal: number;
    lastWaterReminderSent?: Date;
    lastNutritionTipSent?: Date;
    createdAt: Date;
    updatedAt: Date;
  }