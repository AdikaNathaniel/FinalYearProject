import { Injectable, Inject } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Chat } from 'src/shared/schema/chat.schema';
import { CreateChatDto } from 'src/users/dto/create-chat.dto';


@Injectable()
export class ChatService {
    constructor(
        @InjectModel(Chat.name) private readonly ChatModel: Model<Chat>,
    ) {}

    async create(createChatDto: CreateChatDto) {
        try {
            const createdChat = new this.ChatModel(createChatDto);
            await createdChat.save();

            return {
                success: true,
                message: 'Chat created successfully',
                result: createdChat,
            };
        } catch (error) {
            throw error;
        }
    }

    async findAll() {
        try {
            const Chat = await this.ChatModel.find().exec();

            return {
                success: true,
                message: 'Favorite retrieved successfully',
                result: Chat,
            };
        } catch (error) {
            throw error;
        }
    }

    
}