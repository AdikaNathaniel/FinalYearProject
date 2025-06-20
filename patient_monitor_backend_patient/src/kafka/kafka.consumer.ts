import { Controller, Inject } from '@nestjs/common';
import { EventPattern, Payload } from '@nestjs/microservices';
import { VitalsService } from '../vitals/vitals.service';
import { CreateVitalDto } from  'src/users/dto/create-vital.dto'

@Controller()
export class KafkaConsumer {
  constructor(
    private readonly vitalsService: VitalsService,
  ) {}

  @EventPattern('vitals-updates')
  async handleVitalsUpdate(@Payload() message: CreateVitalDto) {
    console.log('Received vitals update:', message);
    await this.vitalsService.create(message);
  }
}