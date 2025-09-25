// src/support/support.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Support, SupportSchema } from 'src/shared/schema/support.schema';
import { SupportService } from './support.service';
import { SupportController } from './support.controller';
import { SupportSmsService } from './sms-support.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Support.name, schema: SupportSchema }]),
  ],
  controllers: [SupportController],
  providers: [SupportService, SupportSmsService],
})
export class SupportModule {}
