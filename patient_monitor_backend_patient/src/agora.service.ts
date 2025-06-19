import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RtcTokenBuilder, RtcRole } from 'agora-access-token';

@Injectable()
export class AgoraService {
  constructor(private configService: ConfigService) {}

  generateToken(channelName: string, uid: number): string {
    const appId = '1e83d054ca2a43dda969689a961ed0a8';
    const appCertificate = 'dee60f54957549afb7a7feccce6e8b72';
    const role = RtcRole.PUBLISHER;
    const expirationTimeInSeconds = 3600; // 1 hour
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      role,
      privilegeExpiredTs,
    );

    return token;
  }

//   healthCheck(): boolean {
//     return !!this.configService.get('AGORA_APP_ID') && 
//            !!this.configService.get('AGORA_APP_CERTIFICATE');
//   }


healthCheck(): boolean {
  const AGORA_APP_ID = '1e83d054ca2a43dda969689a961ed0a8';
  const AGORA_APP_CERTIFICATE = 'dee60f54957549afb7a7feccce6e8b72';

  return !!AGORA_APP_ID && !!AGORA_APP_CERTIFICATE;
}

}