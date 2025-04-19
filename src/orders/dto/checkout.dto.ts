import {
  ArrayMinSize,
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsString,
  ValidateNested,
} from 'class-validator';
import { ObjectId } from 'bson';
import { Transform, Type } from 'class-transformer';

export class checkoutDto {
  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => value || 'defaultSkuPriceId')
  skuPriceId: string = 'defaultSkuPriceId';

  @IsNumber()
  @IsNotEmpty()
  @Transform(({ value }) => value || 1)
  quantity: number = 1;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => value || 'defaultSkuId')
  skuId: string = 'defaultSkuId';

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => value || new ObjectId())
  _id: ObjectId = new ObjectId();
}

export class checkoutDtoArr {
  @IsArray()
  @IsNotEmpty()
  @ValidateNested({ each: true })
  @ArrayMinSize(1)
  @Type(() => checkoutDto) // Required to nest validation properly
  checkoutDetails: checkoutDto[] = [
    new checkoutDto(), // Default with one instance of `checkoutDto`
  ];
}
