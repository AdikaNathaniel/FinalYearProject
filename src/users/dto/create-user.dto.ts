import {
  IsIn,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';
import { userTypes } from 'src/shared/schema/users';

export class CreateUserDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsNotEmpty()
  @IsString()
  email: string;

  @IsNotEmpty()
  @IsString()
  password: string;

  @IsNotEmpty()
  @IsNumber()
  card: number;

  @IsNotEmpty()
  @IsString()
  @IsIn([
    userTypes.ADMIN,
    userTypes.PREGNANT,
    userTypes.DOCTOR,
    userTypes.RELATIVE,
  ])
  type: string;

  @IsString()
  @IsOptional()
  secretToken?: string;

  isVerified?: boolean;
}
