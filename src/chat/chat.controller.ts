import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Delete,
    Put,
    Query,
    HttpCode,
    HttpStatus,
} from '@nestjs/common';
import { ChatService } from 'src/chat/chat.service';
import { CreateChatDto } from 'src/users/dto/create-chat.dto';


@Controller('chat')
export class ChatController {
    constructor(private readonly ChatService: ChatService) {}

    @Post()
    async create(@Body() createChatDto: CreateChatDto) {
        return await this.ChatService.create(createChatDto);
    }

    @Get()
    async findAll() {
        return await this.ChatService.findAll();
    }

}