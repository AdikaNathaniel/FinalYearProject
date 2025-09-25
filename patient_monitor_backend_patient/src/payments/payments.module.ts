import { Module } from '@nestjs/common';
import { PaymentsService } from 'src/payments/payment.service';
import { PaymentsController } from 'src/payments/payment.controller';

@Module({
  controllers: [PaymentsController],
  providers: [PaymentsService],
})
export class PaymentsModule {}
