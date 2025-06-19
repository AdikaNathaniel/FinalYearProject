export interface Pregnancy {
    patientId: string;
    phone: string;
    startDate: Date;
    currentWeek: number;
    lastUpdateSent?: Date;
    nextAppointmentSchedule?: Date;
    createdAt: Date;
    updatedAt: Date;
  }