import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class CsvFile extends Document {
  @Prop({ required: true })
  filename: string;

  @Prop({ required: true })
  path: string;

  @Prop()
  size: number;

  @Prop({ default: 'text/csv' })
  mimetype: string;
}

export const CsvFileSchema = SchemaFactory.createForClass(CsvFile);
