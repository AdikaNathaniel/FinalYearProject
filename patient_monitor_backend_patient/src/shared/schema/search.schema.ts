import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class SearchDocument extends Document {
  @Prop({ required: true })
  index: string;

  @Prop({ required: true })
  documentId: string;

  @Prop({ type: Object, required: true })
  data: Record<string, any>;

  @Prop({ default: Date.now })
  createdAt: Date;

  @Prop({ default: Date.now })
  updatedAt: Date;
}

export const SearchSchema = SchemaFactory.createForClass(SearchDocument);