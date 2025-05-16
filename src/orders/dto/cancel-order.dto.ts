import { IsNotEmpty } from 'class-validator';

export class CancelOrderDto {
  @IsNotEmpty()
  productName: string;
}