import { PartialType } from '@nestjs/mapped-types';
import { CreatePreeclampsiaVitalsDto } from './create-preeclampsia-vitals.dto';

export class UpdatePreeclampsiaVitalsDto extends PartialType(CreatePreeclampsiaVitalsDto) {}