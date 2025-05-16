export interface SmsRecord {
   phone: string;
    message: string;
    type: 'appointment' | 'nutrition' | 'medication' | 'pregnancy';
    status: 'pending' | 'sent' | 'failed';
    sentAt?: Date;
    createdAt: Date;
    updatedAt: Date;
  }
  
  export interface SmsResponse {
    status: string;
    message: string;
    data?: any;
  }