import { IsArray, IsNotEmpty } from 'class-validator';

export class VerifyFaceDto {
  @IsNotEmpty()
  @IsArray()
  descriptor: number[];
}