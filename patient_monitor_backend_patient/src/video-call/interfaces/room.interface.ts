import { Document } from 'mongoose';

export interface Room extends Document {
  name: string;
  participants: string[];
  isActive: boolean;
}