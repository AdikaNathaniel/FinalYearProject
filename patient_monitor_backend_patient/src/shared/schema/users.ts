import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum userTypes {
  ADMIN = 'admin',
  PREGNANT = 'pregnant-woman',
  MIDWIFE = 'midwife',
  DOCTOR = 'doctor',
  RELATIVE = 'relative',
  GENERALUSER = 'wellness-user',
}

@Schema({
  timestamps: true,
})
export class Users extends Document {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  card: string;

  @Prop({ required: true })
  password: string;

  @Prop({
    required: true,
    enum: [
      userTypes.ADMIN,
      userTypes.PREGNANT,
      userTypes.DOCTOR,
      userTypes.RELATIVE,
      userTypes.GENERALUSER,
      userTypes.MIDWIFE,
    ],
  })
  type: string;

  @Prop({ default: false })
  isVerified: boolean;

  @Prop({ default: null })
  otp: string | null;

  @Prop({ default: null })
  otpExpiryTime: Date | null;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: 0 })
  failedLoginAttempts: number;

  @Prop({ default: null })
  lockUntil: Date | null;
}

export const UserSchema = SchemaFactory.createForClass(Users);