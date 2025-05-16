import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Order, OrderSchema } from 'src/shared/schema/order.schema';
import { OrderController } from 'src/orders/orders.controller'
import { OrderService } from 'src/orders/orders.service';
import { StripeService } from 'src/payments/stripe.service';

@Module({
  imports: [MongooseModule.forFeature([{ name: Order.name, schema: OrderSchema }])],
  controllers: [OrderController],
  providers: [OrderService,StripeService],
})
export class OrderModule {}