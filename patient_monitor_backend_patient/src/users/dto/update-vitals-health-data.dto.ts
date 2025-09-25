import { PartialType } from '@nestjs/swagger';
import { CreateVitalsHealthDataDto } from './create-vitals-health-data.dto';

export class UpdateVitalsHealthDataDto extends PartialType(CreateVitalsHealthDataDto) {}