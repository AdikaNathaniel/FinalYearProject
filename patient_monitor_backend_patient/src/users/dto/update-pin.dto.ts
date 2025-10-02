import { IsString, Length, Matches, IsPhoneNumber } from 'class-validator';

export class UpdatePinDto {
  @IsString()
  @Length(6, 6, { message: 'Old PIN must be exactly 6 digits' })
  @Matches(/^\d+$/, { message: 'Old PIN must contain only digits' })
  oldPin: string;

  @IsString()
  @Length(6, 6, { message: 'New PIN must be exactly 6 digits' })
  @Matches(/^\d+$/, { message: 'New PIN must contain only digits' })
  newPin: string;

  @IsString()
  userId: string;

  @IsString()
  @IsPhoneNumber()
  phone: string;
}