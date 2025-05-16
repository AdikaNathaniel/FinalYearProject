export const APPOINTMENT_REMINDER_MESSAGES = {
  WEEK_BEFORE: (appointment: {
    date: Date;
    doctor: string;
    location: string;
    patientName: string;
    purpose: string;
    specialInstructions?: string;
  }) => {
    const dateStr = appointment.date.toLocaleDateString();
  return `Dear ${appointment.patientName}, your appointment for ${appointment.purpose} with Dr. ${appointment.doctor} is in one week (${dateStr}) at ${appointment.location}. ${
    appointment.specialInstructions || ''
  }`.trim();
  },
  TWO_DAYS_BEFORE: (appointment: { date: Date; doctor: string; location: string }) => {
    const dateStr = appointment.date.toLocaleDateString();
    return `Friendly reminder: Your appointment with Dr. ${appointment.doctor} is in 2 days (${dateStr}) at ${appointment.location}.`;
  },
  DAY_BEFORE: (appointment: { date: Date; doctor: string; location: string }) => {
    const dateStr = appointment.date.toLocaleDateString();
    return `Final reminder: Your appointment with Dr. ${appointment.doctor} is tomorrow (${dateStr}) at ${appointment.location}.`;
  },
};

export const NUTRITION_MESSAGES = {
  WATER_INTAKE: (patientName: string, glasses: number) =>
    `Dear ${patientName}, remember to drink ${glasses} glasses of water today for optimal hydration.`,

  SNACK_TIP: (patientName: string, trimester: number, tip: string) =>
    `Dear ${patientName}, nutrition tip for trimester ${trimester}: ${tip}`,

  DEFICIENCY_REMINDER: (patientName: string, tip: string) =>
    `Dear ${patientName}, important: ${tip}`,
};


export const MEDICATION_MESSAGES = {
  DAILY_REMINDER: (medication: { medicationName: string; dosage: string }) =>
    `Time to take your medication: ${medication.medicationName} (${medication.dosage})`,
  WEEKLY_REMINDER: (medication: { medicationName: string; dosage: string }) =>
    `Weekly medication reminder: ${medication.medicationName} (${medication.dosage})`,
  REFILL_REMINDER: (medication: { medicationName: string; refillDate: Date; pharmacy?: { name: string; phone: string } }) => {
    const dateStr = medication.refillDate.toLocaleDateString();
    const pharmacyInfo = medication.pharmacy 
      ? ` at ${medication.pharmacy.name} (${medication.pharmacy.phone})`
      : '';
    return `Reminder to refill ${medication.medicationName} by ${dateStr}${pharmacyInfo}`;
  },
};

export const PREGNANCY_UPDATE_MESSAGES = {
  WEEKLY_UPDATE: (week: number, update: string) => `Week ${week} update: ${update}`,
  APPOINTMENT_SCHEDULE: (message: string) => `Appointment reminder: ${message}`,
};