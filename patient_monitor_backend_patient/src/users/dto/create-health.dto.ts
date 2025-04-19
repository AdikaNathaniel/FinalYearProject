import { IsInt, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateHealthDto {
  @IsInt()
  @IsNotEmpty()
  parity: number;

  @IsInt()
  @IsNotEmpty()
  gravida: number;

  @IsInt()
  @IsNotEmpty()
  gestationalAge: number;

  @IsInt()
  @IsNotEmpty()
  age: number;

  @IsOptional()
  @IsString()
  hasDiabetes?: string;

  @IsOptional()
  @IsString()
  hasAnemia?: string;

  @IsOptional()
  @IsString()
  hasPreeclampsia?: string;

  @IsOptional()
  @IsString()
  hasGestationalDiabetes?: string;
}
