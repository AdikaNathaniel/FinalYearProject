import { IsString, IsOptional, IsNumber, IsArray } from 'class-validator';

export class SearchRequestDto {
  @IsString()
  index: string;

  @IsString()
  query: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  fields?: string[];

  @IsOptional()
  @IsNumber()
  limit?: number;

  @IsOptional()
  @IsNumber()
  offset?: number;
}