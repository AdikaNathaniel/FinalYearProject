import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

export class CreateAppointmentDto {
  @IsEmail()
  email: string;

  @IsNotEmpty()
  day: string;

  @IsNotEmpty()
  time: string;

  @IsNotEmpty()
  @IsString()
  patient_name: string;

  @IsNotEmpty()
  @IsString()
  condition: string;

  @IsString()
  notes?: string;

  // Include a details object (optional)
  details?: {
    patient_name: string;
    condition: string;
    notes?: string;
  };
}