import { Document } from 'mongoose';

export interface ISymptom extends Document {
  username: string;
  feelingHeadache: string;
  feelingDizziness: string;
  vomitingAndNausea: string;
  painAtTopOfTommy: string;
  createdAt: Date;
  updatedAt: Date;
}