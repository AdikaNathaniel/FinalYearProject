import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type DeliveryDocument = Delivery & Document;

@Schema({ timestamps: true })
export class Delivery {
  @Prop({ required: true })
  productName: string; // Identify product for delivery

//   @Prop({ required: true })
//   userId: string;

//   @Prop({ required: true })
//   sellerId: string;

  @Prop({ required: true, enum: ['Pending', 'In Transit', 'Delivered', 'Cancelled'], default: 'Pending' })
  status: string;

  @Prop()
  trackingId?: string;

  @Prop()
  deliveryAddress: string;
}

export const DeliverySchema = SchemaFactory.createForClass(Delivery);