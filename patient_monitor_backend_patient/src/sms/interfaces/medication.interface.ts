export interface Medication {
    patientId: string;
    phone: string;
    name: string;
    dosage: string;
    frequency: 'daily' | 'weekly';
    startDate: Date;
    endDate?: Date;
    refillDate: Date;
    pharmacy: {
      name: string;
      phone: string;
    };
    lastReminderSent?: Date;
    createdAt: Date;
    updatedAt: Date;
  }