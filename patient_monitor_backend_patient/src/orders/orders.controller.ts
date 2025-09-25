import { Body, Controller, Get, Post, Put } from '@nestjs/common';
import { OrderService } from 'src/orders/orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { CancelOrderDto } from 'src/orders/dto/cancel-order.dto';

@Controller('orders')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post()
  async createOrder(@Body() createOrderDto: CreateOrderDto) {
    return await this.orderService.createOrder(createOrderDto);
  }

  @Put('cancel')
  async cancelOrder(@Body() cancelOrderDto: CancelOrderDto) {
    return await this.orderService.cancelOrder(cancelOrderDto);
  }

  @Get()
  async getAllOrders() {
    return await this.orderService.getAllOrders();
  }
}