import { IsString, IsOptional, IsNumber, IsArray } from 'class-validator';
import { Transform, Type } from 'class-transformer';

export class SearchRequestDto {
  @IsString()
  index: string;

  @IsString()
  query: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Transform(({ value }) => {
    // Handle comma-separated string from query params
    if (typeof value === 'string') {
      return value.split(',').map(field => field.trim());
    }
    return value;
  })
  fields?: string[];

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Transform(({ value }) => {
    // Convert string to number for query params
    return typeof value === 'string' ? parseInt(value, 10) : value;
  })
  limit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Transform(({ value }) => {
    // Convert string to number for query params
    return typeof value === 'string' ? parseInt(value, 10) : value;
  })
  offset?: number;
}