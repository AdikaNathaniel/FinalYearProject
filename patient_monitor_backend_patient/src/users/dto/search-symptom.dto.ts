import { IsString, IsNotEmpty } from 'class-validator';

export class SearchSymptomDto {
  @IsString()
  @IsNotEmpty()
  query: string;
}