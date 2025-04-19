import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChatbotController } from './chat.controller';
import { ChatbotService } from './chat.service';
import { Chat, ChatSchema } from 'src/shared/schema/chat.schema';

@Module({
  imports: [MongooseModule.forFeature([{ name: Chat.name, schema: ChatSchema }])],
  controllers: [ChatbotController],
  providers: [ChatbotService],
})
export class ChatbotModule {}
