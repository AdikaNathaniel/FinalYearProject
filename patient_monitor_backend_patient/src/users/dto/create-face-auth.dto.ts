import { IsArray, IsNotEmpty, IsString } from 'class-validator';

export class CreateFaceAuthDto {
  @IsNotEmpty()
  @IsString()
  userId: string;

  @IsNotEmpty()
  @IsString()
  username: string;

  @IsNotEmpty()
  @IsArray()
  faceDescriptor: number[];

  @IsNotEmpty()
  @IsString()
  role: string;
}