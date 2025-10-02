import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

export class SendSmsDto {
  @IsNotEmpty()
  @IsString()
  phone: string;

  @IsNotEmpty()
  @IsString()
  message: string;

  @IsNotEmpty()
  @IsEnum(['appointment', 'nutrition', 'medication', 'pregnancy'])
  type: string;
}