import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Delivery, DeliveryDocument } from 'src/shared/schema/delivery.schema';
import { MQService } from 'src/delivery/mq.service';

@Injectable()
export class DeliveryService {
  constructor(
    @InjectModel(Delivery.name) private deliveryModel: Model<DeliveryDocument>,
    private readonly mqService: MQService
  ) {}

  async createDelivery(data: Partial<Delivery>): Promise<Delivery> {
    return new this.deliveryModel(data).save();
  }

  async updateStatus(productName: string, status: string): Promise<Delivery | null> {
    try {
      const updatedDelivery = await this.deliveryModel.findOneAndUpdate(
        { productName },
        { status },
        { new: true }
      );

      if (!updatedDelivery) {
        throw new Error('Delivery not found');
      }

      // Attempt to send a message to RabbitMQ
      try {
        await this.mqService.sendMessage({
          productName,
          status,
          deliveryAddress: updatedDelivery.deliveryAddress,
        });
      } catch (mqError) {
        console.error('Error sending message to RabbitMQ:', mqError);
        throw new Error(`Failed to send message to RabbitMQ: ${mqError.message}`);
      }

      return updatedDelivery;
    } catch (error) {
      console.error('Error in updateStatus:', {
        message: error.message,
        stack: error.stack,
        productName,
        status,
      });
      throw error; // Rethrow to handle in the controller
    }
  }

  async getStatus(productName: string): Promise<{ productName: string; status: string } | null> {
    const delivery = await this.deliveryModel.findOne({ productName });

    if (!delivery) {
      return null;
    }

    return {
      productName: delivery.productName,
      status: delivery.status,
    };
  }
}