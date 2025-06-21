import { Controller } from '@nestjs/common';
import { EventPattern, Payload } from '@nestjs/microservices';
import { VitalsService } from 'src/vitals/vitals.service';
import { CreateVitalDto } from 'src/users/dto/create-vital.dto';

@Controller()
export class KafkaConsumer {
  constructor(private readonly vitalsService: VitalsService) {}

  @EventPattern('vitals-updates')
  async handleVitalsUpdate(@Payload() message: CreateVitalDto) {
    console.log('📩 [Kafka] Received message:', JSON.stringify(message, null, 2));
    try {
      const savedVital = await this.vitalsService.create(message);
      console.log('💾 [Kafka] Saved to MongoDB:', savedVital && (savedVital.id || JSON.stringify(savedVital)));
    } catch (error) {
      console.error('❌ [Kafka] Save failed:', error.message);
      console.error(error.stack);
    }
  }
}