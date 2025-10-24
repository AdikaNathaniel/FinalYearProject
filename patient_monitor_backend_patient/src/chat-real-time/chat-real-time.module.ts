import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChatGateway } from './chat-gateway';
import { MessageService } from './message.service';
import { Message, MessageSchema } from '../shared/schema/message.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Message.name, schema: MessageSchema }])
  ],
  providers: [ChatGateway, MessageService],
  exports: [MessageService],
})
export class ChatRealTimeModule {}