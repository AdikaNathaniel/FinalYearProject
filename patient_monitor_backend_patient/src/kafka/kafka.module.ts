import { Module, forwardRef } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { KafkaService } from './kafka.service';
import { KafkaConsumer } from './kafka.consumer';
import { VitalsModule } from 'src/vitals/vital.module'; // Adjust path as needed

@Module({
  imports: [
    forwardRef(() => VitalsModule), // Import the module that provides VitalsService
    ClientsModule.register([
      {
        name: 'KAFKA_SERVICE',
        transport: Transport.KAFKA,
        options: {
          client: {
            brokers: [process.env.KAFKA_BROKER || 'localhost:9092'],
          },
          consumer: {
            groupId: 'pregnancy-monitor-consumer',
          },
        },
      },
    ]),
  ],
  providers: [KafkaService, KafkaConsumer],
  exports: [KafkaService],
})
export class KafkaModule {}