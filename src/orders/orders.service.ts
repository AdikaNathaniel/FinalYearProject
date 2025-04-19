import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderDocument } from 'src/shared/schema/order.schema';
import { CreateOrderDto } from './dto/create-order.dto';
import { CancelOrderDto } from 'src/orders/dto/cancel-order.dto';
import { StripeService } from  'src/payments/stripe.service';

@Injectable()
export class OrderService {
  constructor(
    @InjectModel(Order.name) private orderDB: Model<OrderDocument>,
    private readonly stripeService: StripeService, // Inject Stripe service
  ) {}

  // ✅ Create an Order and Generate Stripe Payment Session
  async createOrder(createOrderDto: CreateOrderDto) {
    try {
      const { productName, quantity } = createOrderDto;

      // Step 1: Create order in the database (Initially "Pending")
      const newOrder = new this.orderDB({
        productName,
        quantity,
        status: 'Pending',
      });

      await newOrder.save();

      // Step 2: Create Stripe Checkout Session (Dummy amount for now)
      const session = await this.stripeService.createCheckoutSession(5000, 'test@example.com'); // Replace with real values

      return {
        message: 'Order created successfully. Proceed with payment.',
        success: true,
        sessionUrl: session.url, // Send session URL for frontend redirection
        orderId: newOrder._id, // Return order ID
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  // ✅ Handle Payment Success (Webhook)
  async handlePaymentSuccess(sessionId: string) {
    try {
      // Find order using session ID (assuming it’s stored)
      const order = await this.orderDB.findOne({ sessionId });

      if (!order) {
        throw new BadRequestException('Order not found');
      }

      // Update order status to "Paid"
      order.status = 'Paid';
      await order.save();

      return { message: 'Order payment confirmed', success: true };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  // ✅ Cancel an Order
  async cancelOrder(cancelOrderDto: CancelOrderDto) {
    try {
      const { productName } = cancelOrderDto;

      const deletedOrder = await this.orderDB.findOneAndDelete({ productName });

      if (!deletedOrder) {
        throw new BadRequestException('Order not found');
      }

      return {
        message: 'Order cancelled successfully',
        success: true,
        result: deletedOrder,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  // ✅ Get All Orders
  async getAllOrders() {
    try {
      const orders = await this.orderDB.find();
      return {
        message: 'Orders retrieved successfully',
        success: true,
        result: orders,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }
}
