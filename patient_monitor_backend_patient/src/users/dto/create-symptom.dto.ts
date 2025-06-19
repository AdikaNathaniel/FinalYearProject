import { IsString, IsNotEmpty } from 'class-validator';

export class CreateSymptomDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsString()
  @IsNotEmpty()
  feelingHeadache: string;

  @IsString()
  @IsNotEmpty()
  feelingDizziness: string;

  @IsString()
  @IsNotEmpty()
  vomitingAndNausea: string;

  @IsString()
  @IsNotEmpty()
  painAtTopOfTommy: string;
}