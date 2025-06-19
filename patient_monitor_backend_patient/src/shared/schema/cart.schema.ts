import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Cart extends Document {
  @Prop({ type: String, required: true })
  productName: string; // Store only the product name

  @Prop({ type: String, required: false }) // Optional productId
  productId?: string;

  @Prop({ type: Number, required: true, default: 1 })
  quantity: number; // Quantity of the product
}

export type CartDocument = Cart & Document;
export const CartSchema = SchemaFactory.createForClass(Cart);