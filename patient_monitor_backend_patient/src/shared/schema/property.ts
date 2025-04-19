import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export enum PropertyType {
  Residential = 'Residential',
  Commercial = 'Commercial',
  Industrial = 'Industrial',
  Land = 'Land',
}

// Define the nested schemas first
const LocationSchema = new MongooseSchema({
  address: { type: String, required: true },
  city: { type: String, required: true },
  state: { type: String, required: true },
  zip_code: { type: String, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
});

const SizeSchema = new MongooseSchema({
  area: { type: Number, required: true },
  bedrooms: { type: Number, required: true },
  bathrooms: { type: Number, required: true },
});

@Schema({ timestamps: true })
export class Property extends Document {
  @Prop({ required: true })
  propertyName: string;

  @Prop({ required: true })
  description: string;

  @Prop({ required: true, enum: PropertyType })
  property_type: PropertyType;

  @Prop({ type: LocationSchema, required: true })
  location: {
    address: string;
    city: string;
    state: string;
    zip_code: string;
    latitude: number;
    longitude: number;
  };

  @Prop({ required: true })
  price: number;

  @Prop({ type: SizeSchema, required: true })
  size: {
    area: number;
    bedrooms: number;
    bathrooms: number;
  };

  @Prop({ type: [String], default: [] })
  amenities: string[];

  @Prop({ type: [String], default: [] })
  propetyImage: string[];

  @Prop({ type: [String], default: [] })
  videos: string[];

  @Prop({ type: String, default: '' })
  virtual_tour: string;

  @Prop({ type: Boolean, default: false })
  availability: boolean;

  @Prop({ type: Date, default: Date.now })
  created_at: Date;

  @Prop({ type: Date, default: Date.now })
  updated_at: Date;

  @Prop({ type: String, required: true })
  agent_id: string;

  @Prop({ type: String, required: true })
  property_status: string;
}

export const PropertySchema = SchemaFactory.createForClass(Property);