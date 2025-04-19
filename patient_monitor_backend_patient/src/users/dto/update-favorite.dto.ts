import { IsString, IsNumber, IsOptional } from 'class-validator';

export class UpdateFavoriteDto {
  @IsString()
  @IsOptional()
  productName?: string;

//   @IsNumber()
//   @IsOptional()
//   price?: number;

//   @IsString()
//   @IsOptional()
//   status?: string;

  @IsString()
  @IsOptional()
  image?: string;

  @IsString()
  @IsOptional()
  category?: string;
}