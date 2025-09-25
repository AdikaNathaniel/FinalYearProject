import { Controller, Post, Body } from '@nestjs/common';
import { ChatbotService } from './chat.service';
import { CreateChatDto } from 'src/users/dto/create-chat.dto';

@Controller('api/v1/chatbot')
export class ChatbotController {
  constructor(private readonly chatbotService: ChatbotService) {}

  @Post('message')
  async generateResponse(@Body() createChatDto: CreateChatDto) {
    return await this.chatbotService.generateResponse(createChatDto);
  }
}
