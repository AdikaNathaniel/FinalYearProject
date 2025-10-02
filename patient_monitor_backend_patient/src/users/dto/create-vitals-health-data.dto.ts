import { 
  IsEnum, 
  IsNumber, 
  IsOptional, 
  IsDate, 
  IsObject, 
  ValidateNested, 
  Min, 
  Max, 
  IsString 
} from 'class-validator';
import { Type } from 'class-transformer';
import { InputMethod } from 'src/shared/schema/vitals-health-data.schema';
import { ApiProperty } from '@nestjs/swagger';

class BloodPressureDto {
  @ApiProperty({ description: 'Systolic blood pressure', minimum: 60, maximum: 250 })
  @IsNumber()
  @Min(60)
  @Max(250)
  systolic: number;

  @ApiProperty({ description: 'Diastolic blood pressure', minimum: 40, maximum: 150 })
  @IsNumber()
  @Min(40)
  @Max(150)
  diastolic: number;
}

export class CreateVitalsHealthDataDto {
  @ApiProperty({ description: 'User ID associated with the vitals' })
  @IsString()
  userId: string;   

  @ApiProperty({ enum: InputMethod, description: 'Method of input' })
  @IsEnum(InputMethod)
  inputMethod: InputMethod;

  @ApiProperty({ 
    type: BloodPressureDto, 
    required: false, 
    description: 'Blood pressure reading' 
  })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => BloodPressureDto)
  bloodPressure?: BloodPressureDto;

  @ApiProperty({ required: false, minimum: 30, maximum: 300 })
  @IsOptional()
  @IsNumber()
  @Min(30)
  @Max(300)
  heartRate?: number;

  @ApiProperty({ required: false, minimum: 70, maximum: 100 })
  @IsOptional()
  @IsNumber()
  @Min(70)
  @Max(100)
  spO2?: number;

  @ApiProperty({ required: false, minimum: 50, maximum: 400 })
  @IsOptional()
  @IsNumber()
  @Min(50)
  @Max(400)
  bloodGlucose?: number;

  @ApiProperty({ required: false, minimum: 0, maximum: 1000 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1000)
  proteinInUrine?: number;

  @ApiProperty({ required: false, description: 'Timestamp of the reading' })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  timestamp?: Date;

  @ApiProperty({ required: false, description: 'Wearable device ID if applicable' })
  @IsOptional()
  @IsString()
  wearableDeviceId?: string;
}
