import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Model } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';
import { Room } from 'src/shared/schema/room.schema';

@WebSocketGateway({
  cors: {
    origin: ['http://localhost:3000', 'http://localhost:8080'], // Add the URL where your Flutter web app will run
    methods: ['GET', 'POST'],
    credentials: true,
  },
})
export class VideoGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(@InjectModel(Room.name) private roomModel: Model<Room>) {}

  async handleConnection(@ConnectedSocket() socket: Socket) {
    console.log(`Client connected: ${socket.id}`);
  }

  async handleDisconnect(@ConnectedSocket() socket: Socket) {
    console.log(`Client disconnected: ${socket.id}`);
    // Clean up rooms when participants disconnect
    const rooms = await this.roomModel.find({
      participants: socket.id,
    });
    
    for (const room of rooms) {
      const updatedParticipants = room.participants.filter(id => id !== socket.id);
      await this.roomModel.findByIdAndUpdate(room._id, {
        participants: updatedParticipants,
        isActive: updatedParticipants.length >= 2,
      });
      
      if (updatedParticipants.length === 1) {
        this.server.to(room.name).emit('participant_left');
      }
    }
  }

  @SubscribeMessage('join_room')
  async joinRoom(
    @MessageBody() roomName: string,
    @ConnectedSocket() socket: Socket,
  ) {
    try {
      let room = await this.roomModel.findOne({ name: roomName });
      
      if (!room) {
        room = await this.roomModel.create({
          name: roomName,
          participants: [socket.id],
          isActive: false,
        });
        socket.join(roomName);
        return;
      }

      if (room.participants.length >= 2) {
        socket.emit('too_many_participants');
        return;
      }

      room.participants.push(socket.id);
      room.isActive = room.participants.length >= 2;
      await room.save();

      socket.join(roomName);

      if (room.participants.length === 2) {
        this.server.to(roomName).emit('participant_ready');
      }
    } catch (error) {
      console.error('Error joining room:', error);
      socket.emit('error', { message: 'Failed to join room' });
    }
  }

  @SubscribeMessage('send_connection_offer')
  async sendConnectionOffer(
    @MessageBody() data: { offer: any; roomName: string },
    @ConnectedSocket() socket: Socket,
  ) {
    this.server.to(data.roomName).except(socket.id).emit('receive_connection_offer', {
      offer: data.offer,
    });
  }

  @SubscribeMessage('send_answer')
  async sendAnswer(
    @MessageBody() data: { answer: any; roomName: string },
    @ConnectedSocket() socket: Socket,
  ) {
    this.server.to(data.roomName).except(socket.id).emit('receive_answer', {
      answer: data.answer,
    });
  }

  @SubscribeMessage('send_candidate')
  async sendCandidate(
    @MessageBody() data: { candidate: any; roomName: string },
    @ConnectedSocket() socket: Socket,
  ) {
    this.server.to(data.roomName).except(socket.id).emit('receive_candidate', {
      candidate: data.candidate,
    });
  }
}