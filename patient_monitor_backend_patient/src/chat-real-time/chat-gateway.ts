import {
  WebSocketGateway,
  MessageBody,
  SubscribeMessage,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Socket, Server } from 'socket.io';
import { Injectable } from '@nestjs/common';

// Interface for a chat message
interface ChatMessage {
  id: string;
  senderId: string;
  receiverId: string;
  content: string;
  timestamp: Date;
  isRead: boolean;
}

// Interface for a chat room (conversation between two users)
interface ChatRoom {
  id: string;
  participants: string[];
  messages: ChatMessage[];
}

@Injectable()
@WebSocketGateway(3009, { cors: { origin: '*' } })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  private connectedUsers: Map<string, { socketId: string; userId: string; role: string }> = new Map();
  private chatRooms: Map<string, ChatRoom> = new Map();

  handleConnection(client: Socket): void {
    console.log('New User Connected...', client.id);
  }

  @SubscribeMessage('register')
  handleRegister(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { userId: string; role: string }
  ): void {
    this.connectedUsers.set(client.id, {
      socketId: client.id,
      userId: data.userId,
      role: data.role,
    });

    console.log(`User registered: ${data.userId} as ${data.role}`);
    client.broadcast.emit('user-joined', {
      message: `New ${data.role} joined: ${data.userId}`,
    });
  }

  handleDisconnect(client: Socket): void {
    console.log('User Disconnected...', client.id);
    const user = this.connectedUsers.get(client.id);

    if (user) {
      this.connectedUsers.delete(client.id);
      this.server.emit('user-left', {
        message: `${user.role} left: ${user.userId}`,
      });
    }
  }

  @SubscribeMessage('startConversation')
  handleStartConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { targetUserId: string }
  ): void {
    const currentUser = this.connectedUsers.get(client.id);

    if (!currentUser) {
      client.emit('error', { message: 'You must register first' });
      return;
    }

    const participants = [currentUser.userId, data.targetUserId].sort();
    const roomId = `room_${participants.join('_')}`;

    if (!this.chatRooms.has(roomId)) {
      this.chatRooms.set(roomId, {
        id: roomId,
        participants,
        messages: [],
      });
    }

    client.join(roomId);
    client.emit('conversationStarted', { roomId });

    const room = this.chatRooms.get(roomId);
    client.emit('messageHistory', {
      roomId,
      messages: room.messages,
    });
  }

  @SubscribeMessage('sendMessage')
  handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; content: string; receiverId: string }
  ): void {
    const sender = this.connectedUsers.get(client.id);

    if (!sender) {
      client.emit('error', { message: 'You must register first' });
      return;
    }

    const room = this.chatRooms.get(data.roomId);
    if (!room) {
      client.emit('error', { message: 'Conversation not found' });
      return;
    }

    const message: ChatMessage = {
      id: Date.now().toString(),
      senderId: sender.userId,
      receiverId: data.receiverId,
      content: data.content,
      timestamp: new Date(),
      isRead: false,
    };

    room.messages.push(message);
    this.server.to(data.roomId).emit('newMessage', message);
  }

  @SubscribeMessage('getMessageHistory')
  handleGetMessageHistory(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string }
  ): void {
    const room = this.chatRooms.get(data.roomId);
    if (!room) {
      client.emit('error', { message: 'Conversation not found' });
      return;
    }

    client.emit('messageHistory', {
      roomId: data.roomId,
      messages: room.messages,
    });
  }

  @SubscribeMessage('markAsRead')
  handleMarkAsRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; messageIds: string[] }
  ): void {
    const room = this.chatRooms.get(data.roomId);
    if (!room) {
      client.emit('error', { message: 'Conversation not found' });
      return;
    }

    room.messages.forEach((message) => {
      if (data.messageIds.includes(message.id)) {
        message.isRead = true;
      }
    });

    this.server.to(data.roomId).emit('messagesRead', {
      roomId: data.roomId,
      messageIds: data.messageIds,
    });
  }
}