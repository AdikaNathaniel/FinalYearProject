export interface Appointment {
    patientId: string;
    phone: string;
    date: Date;
    doctor: string;
    location: string;
    specialInstructions?: string;
    confirmed?: boolean;
    reminders: {
      weekBefore: boolean;
      twoDaysBefore: boolean;
      dayBefore: boolean;
    };
    createdAt: Date;
    updatedAt: Date;
  }