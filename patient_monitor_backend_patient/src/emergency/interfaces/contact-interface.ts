import { Document } from 'mongoose';

export interface IContact extends Document {
  userId: string;
  name: string;
  phoneNumber: string;
  email?: string;
  relationship?: string;
  isActive: boolean;
}