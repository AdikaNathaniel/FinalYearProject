
// src/shared/shared.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MessageService } from './sms-message.service';

@Module({
  imports: [
    // Make sure ConfigModule is imported since MessageService depends on it
    ConfigModule,
  ],
  providers: [MessageService],
  exports: [MessageService], 
})
export class SharedModule {}