import { IsNotEmpty, IsNumber, IsArray, IsString } from 'class-validator';

export class CreateMedicDto {
  @IsNotEmpty()
  @IsString()
  readonly fullName: string;

  @IsString()
  readonly hospital?: string;

  readonly profilePhoto?: any;

  @IsNotEmpty()
  @IsString()
  readonly specialization: string;

  @IsNotEmpty()
  @IsString()
  readonly yearsOfPractice: string;

  @IsNotEmpty()
  readonly consultationHours: {
    days: string[];
    startTime: string;
    endTime: string;
  };

  @IsNotEmpty()
  @IsString({ each: true })
  readonly languagesSpoken: string;

  @IsNotEmpty()
  @IsString()
  readonly phoneNumber: string;

  @IsNotEmpty()
  @IsString()
  readonly consultationFee: string;
}