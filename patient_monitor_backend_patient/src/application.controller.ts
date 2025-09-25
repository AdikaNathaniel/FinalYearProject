import { Controller, Get, Param } from '@nestjs/common';
import { AppwriteService } from './appwrite.service';
import { AgoraService } from './agora.service';

@Controller('videcall')  // Important prefix
export class AppController {
  constructor(
    private readonly appwriteService: AppwriteService,
    private readonly agoraService: AgoraService,
  ) {}

  @Get('healthy')
  async healthCheck() {
    const appwriteHealthy = await this.appwriteService.healthCheck();
    const agoraHealthy = this.agoraService.healthCheck();
    
    console.log('Appwrite connection status:', appwriteHealthy ? 'Connected' : 'Failed');
    console.log('Agora connection status:', agoraHealthy ? 'Connected' : 'Failed');
    
    return {
      appwrite: appwriteHealthy,
      agora: agoraHealthy,
    };
  }

  @Get('token/:channel/:uid')
  async generateToken(@Param('channel') channel: string, @Param('uid') uid: number) {
    return {
      token: this.agoraService.generateToken(channel, uid),
    };
  }
}