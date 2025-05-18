import { IsNotEmpty, IsString } from 'class-validator';

export class SendSmsDto {
  @IsNotEmpty()
  @IsString()
  message: string;
}