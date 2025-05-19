import { IsString, Length, Matches, IsPhoneNumber } from 'class-validator';

export class CreatePinDto {
  @IsString()
  @Length(6, 6, { message: 'PIN must be exactly 6 digits' })
  @Matches(/^\d+$/, { message: 'PIN must contain only digits' })
  pin: string;

  @IsString()
  userId: string;

  @IsString()
  @IsPhoneNumber()
  phone: string;
}