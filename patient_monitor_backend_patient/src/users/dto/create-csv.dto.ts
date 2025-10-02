import { IsNotEmpty } from 'class-validator';

export class CreateCsvDto {
  @IsNotEmpty()
  filename: string;

  @IsNotEmpty()
  path: string;

  size?: number;
  mimetype?: string;
}
