import { IsNumber, IsArray, IsString, IsOptional } from 'class-validator';

export class UpdateMedicDto {
  @IsOptional()
  @IsString()
  readonly hospital?: string;

  readonly profilePhoto?: any;

  @IsOptional()
  @IsString()
  readonly specialization?: string;

  @IsOptional()
  @IsString()
  readonly yearsOfPractice?: string;

  @IsOptional()
  readonly consultationHours?: {
    days?: string[];
    startTime?: string;
    endTime?: string;
  };

  @IsOptional()
  @IsString()
  readonly languagesSpoken?: string;

  @IsOptional()
  @IsString()
  readonly phoneNumber?: string;

  @IsOptional()
  @IsNumber()
  readonly consultationFee?: string;
}