import { IsString, IsNotEmpty } from 'class-validator';

export class CreatePredictionHardwareDto {
  @IsString()
  @IsNotEmpty()
  preeclampsia_risk: string;

  @IsString()
  @IsNotEmpty()
  anemia_risk: string;

  @IsString()
  @IsNotEmpty()
  gdm_risk: string;
}