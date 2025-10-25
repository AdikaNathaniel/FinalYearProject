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
import { MessageService } from './message.service';

interface ChatMessage {
  id: string;
  senderId: string;
  receiverId: string;
  content: string;
  timestamp: Date;
  isRead: boolean;
}

interface ChatRoom {
  id: string;
  participants: string[];
  lastActivity: Date;
}

@Injectable()
@WebSocketGateway({ 
  cors: { 
    origin: '*',
    credentials: false
  } 
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  constructor(private readonly messageService: MessageService) {}

  private connectedUsers: Map<string, { socketId: string; userId: string; role: string }> = new Map();
  private chatRooms: Map<string, ChatRoom> = new Map();

  handleConnection(client: Socket): void {
    console.log('New User Connected...', client.id);
    console.log('Client origin:', client.handshake.headers.origin);
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
    client.broadcast.emit('user-status-changed', {
      userId: data.userId,
      role: data.role,
      status: 'online',
      timestamp: new Date(),
    });
  }

  handleDisconnect(client: Socket): void {
    console.log('User Disconnected...', client.id);
    const user = this.connectedUsers.get(client.id);

    if (user) {
      this.connectedUsers.delete(client.id);
      this.server.emit('user-status-changed', {
        userId: user.userId,
        role: user.role,
        status: 'offline',
        timestamp: new Date(),
      });
    }
  }

  @SubscribeMessage('startConversation')
  async handleStartConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { targetUserId: string }
  ): Promise<void> {
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
        lastActivity: new Date(),
      });
    }

    client.join(roomId);
    client.emit('conversationStarted', { roomId });

    // Load message history from database
    try {
      const messages = await this.messageService.getConversationMessages(
        currentUser.userId,
        data.targetUserId
      );
      client.emit('messageHistory', {
        roomId,
        messages: messages,
      });
    } catch (error) {
      console.error('Error loading message history:', error);
      client.emit('error', { message: 'Failed to load message history' });
    }
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; content: string; receiverId: string }
  ): Promise<void> {
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

    try {
      // Save message to database
      const savedMessage = await this.messageService.saveMessage({
        senderId: sender.userId,
        receiverId: data.receiverId,
        content: data.content,
        roomId: data.roomId,
        timestamp: new Date(),
        isRead: false,
      });

      // Update room activity
      room.lastActivity = new Date();

      // Emit to all participants in the room
      this.server.to(data.roomId).emit('newMessage', {
        id: savedMessage._id?.toString() || Date.now().toString(),
        senderId: savedMessage.senderId,
        receiverId: savedMessage.receiverId,
        content: savedMessage.content,
        timestamp: savedMessage.timestamp,
        isRead: savedMessage.isRead,
        roomId: savedMessage.roomId,
      });

      // Notify receiver if they're online
      const receiverSocket = this.findUserSocket(data.receiverId);
      if (receiverSocket && !receiverSocket.rooms.has(data.roomId)) {
        receiverSocket.emit('newConversation', {
          roomId: data.roomId,
          lastMessage: data.content,
          senderId: sender.userId,
          timestamp: new Date(),
        });
      }

    } catch (error) {
      console.error('Error saving message:', error);
      client.emit('error', { message: 'Failed to send message' });
    }
  }

  @SubscribeMessage('markAsRead')
  async handleMarkAsRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; messageIds: string[] }
  ): Promise<void> {
    const room = this.chatRooms.get(data.roomId);
    if (!room) {
      client.emit('error', { message: 'Conversation not found' });
      return;
    }

    try {
      // Update messages as read in database
      await this.messageService.markMessagesAsRead(data.messageIds);

      this.server.to(data.roomId).emit('messagesRead', {
        roomId: data.roomId,
        messageIds: data.messageIds,
      });
    } catch (error) {
      console.error('Error marking messages as read:', error);
      client.emit('error', { message: 'Failed to mark messages as read' });
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; isTyping: boolean }
  ): void {
    const user = this.connectedUsers.get(client.id);
    if (user && data.roomId) {
      client.to(data.roomId).emit('userTyping', {
        userId: user.userId,
        isTyping: data.isTyping,
        roomId: data.roomId,
      });
    }
  }

  private findUserSocket(userId: string): Socket | null {
    for (const [socketId, user] of this.connectedUsers.entries()) {
      if (user.userId === userId) {
        return this.server.sockets.sockets.get(socketId) || null;
      }
    }
    return null;
  }

  // Helper method to get online users
  @SubscribeMessage('getOnlineUsers')
  handleGetOnlineUsers(@ConnectedSocket() client: Socket): void {
    const onlineUsers = Array.from(this.connectedUsers.values()).map(user => ({
      userId: user.userId,
      role: user.role,
    }));

    client.emit('onlineUsers', onlineUsers);
  }
}