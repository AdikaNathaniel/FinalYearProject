import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true, collection: 'search_queries' })
export class SearchQuery extends Document {
  @Prop({ required: true })
  index: string;

  @Prop({ required: true })
  query: string;

  @Prop({ type: [String], default: [] })
  fields: string[];

  @Prop({ default: 10 })
  limit: number;

  @Prop({ default: 0 })
  offset: number;

  @Prop({ required: true })
  resultsCount: number;

  @Prop({ default: Date.now })
  timestamp: Date;
}

export const SearchQuerySchema = SchemaFactory.createForClass(SearchQuery);