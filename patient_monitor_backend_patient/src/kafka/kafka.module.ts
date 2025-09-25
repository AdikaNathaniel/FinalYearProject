import { Module, forwardRef } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { KafkaService } from './kafka.service';
import { KafkaConsumer } from './kafka.consumer';
import { VitalsModule } from  'src/vitals/vital.module';

@Module({
  imports: [
    forwardRef(() => VitalsModule),
    ClientsModule.register([
      {
        name: 'KAFKA_SERVICE',
        transport: Transport.KAFKA,
        options: {
          client: {
            brokers: ['localhost:9092'], // Use 'pm-kafka:9092' if in Docker network
          },
          consumer: {
            groupId: 'vitals-consumer-' + Math.random().toString(36).substring(2),
          },
        },
      },
    ]),
  ],
  providers: [KafkaService, KafkaConsumer],
  exports: [KafkaService],
})
export class KafkaModule {}