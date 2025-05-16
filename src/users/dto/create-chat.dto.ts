import { IsString, IsNotEmpty, IsISO8601 } from 'class-validator';

export class CreateChatDto {
  @IsString()
  @IsNotEmpty()
  message: string;

  @IsString()
  @IsNotEmpty()
  receiverEmail: string;  // Changed from receiverMail to match your schema

  @IsISO8601()  // Add validation for ISO timestamp
  timestamps: string = new Date().toISOString();
}