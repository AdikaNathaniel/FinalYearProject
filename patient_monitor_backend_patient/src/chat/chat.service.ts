import { Injectable } from '@nestjs/common';
import { CreateChatDto } from 'src/users/dto/create-chat.dto';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Chat } from 'src/shared/schema/chat.schema';
import axios from 'axios';

@Injectable()
export class ChatbotService {
  private readonly apiUrl = 'https://models.inference.ai.azure.com/chat/completions';
  private readonly apiKey = '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';

  constructor(@InjectModel(Chat.name) private chatModel: Model<Chat>) {}

  async generateResponse(createChatDto: CreateChatDto): Promise<any> {
    try {
      // Prepend the instruction to the user's input
      const userInputWithInstruction = `${createChatDto.content} (formatted with headings and bullet points for clarity)`;

      const payload = {
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: 'You are a helpful assistant.' },
          { role: 'user', content: userInputWithInstruction },
        ],
        temperature: 1,
        // max_tokens: 4096,
        max_tokens: 32000,
        top_p: 1,
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
      });

      // Extract the assistant's response
      const assistantResponse = response.data.choices[0].message.content;

      // Save the chat to the database
      const chat = new this.chatModel({
        userMessage: createChatDto.content,
        assistantResponse,
      });
      await chat.save();

      // Return structured response with the assistant's response in the result object
      return {
        success: true,
        timestamps: new Date().toISOString(),
        statusCode: 200,
        path: '/api/v1/chatbot/message',
        message: 'Response generated successfully',
        result: {
          response: assistantResponse,
        },
      };
    } catch (error) {
      console.error('Error generating response:', error);
      return {
        success: false,
        timestamps: new Date().toISOString(),
        statusCode: error.response?.status || 500,
        path: '/api/v1/chatbot/message',
        message: error.response?.data?.error || 'Failed to generate response.',
        result: null,
      };
    }
  }
}
