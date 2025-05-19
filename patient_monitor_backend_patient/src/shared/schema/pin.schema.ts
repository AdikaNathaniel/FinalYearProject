import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { 
  PIN_LENGTH, 
  MAX_PIN_ATTEMPTS,
  PIN_LOCK_DURATION_MINUTES 
} from 'src/pin/pin.constants';

@Schema({
  timestamps: true,
  collection: 'pins',
})
export class Pin extends Document {
  @Prop({ 
    required: true, 
    unique: true,
    index: true 
  })
  userId: string;

  @Prop({ 
    required: true,
    length: PIN_LENGTH
  })
  pin: string;

  @Prop({ 
    default: 0,
    min: 0,
    max: MAX_PIN_ATTEMPTS 
  })
  attempts: number;

  @Prop({ default: null })
  lastAttempt: Date;

  @Prop({ default: null })
  lockedUntil: Date;

  @Prop({ required: true })
  phone: string;
}

export const PinSchema = SchemaFactory.createForClass(Pin);

// Auto-expire locks when their time is up
PinSchema.index({ lockedUntil: 1 }, { expireAfterSeconds: 0 });