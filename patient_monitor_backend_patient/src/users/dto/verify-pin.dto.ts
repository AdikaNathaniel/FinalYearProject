import { IsString, Length, Matches } from 'class-validator';
import { PIN_LENGTH } from 'src/pin/pin.constants';

export class VerifyPinDto {
  @IsString()
  @Length(PIN_LENGTH, PIN_LENGTH, { 
    message: `PIN must be exactly ${PIN_LENGTH} digits` 
  })
  @Matches(/^[0-9]+$/, { 
    message: 'PIN must contain only numbers' 
  })
  pin: string;

  @IsString()
  userId: string;
}