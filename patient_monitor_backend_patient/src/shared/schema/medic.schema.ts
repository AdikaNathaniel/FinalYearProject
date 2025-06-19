import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Medic extends Document {
  @Prop({ required: true, unique: true })
  fullName: string;

  @Prop()
  hospital: string;

  @Prop()
  profilePhoto: string;

  @Prop({ required: true })
  specialization: string;

  @Prop({ required: true })
  yearsOfPractice: string;

  @Prop({ type: Object })
  consultationHours: {
    days: string[];
    startTime: string;
    endTime: string;
  };

  @Prop([String])
  languagesSpoken: string[];  

  @Prop({ required: true })
  phoneNumber: string;

  @Prop({ required: true })
  consultationFee: string;
}

export const MedicSchema = SchemaFactory.createForClass(Medic);