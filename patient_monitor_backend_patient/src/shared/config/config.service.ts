// import { Injectable } from '@nestjs/common';
// import { ConfigService as NestConfigService } from '@nestjs/config';

// @Injectable()
// export class ConfigService {
//   constructor(private configService: NestConfigService) {}

//   get mongoUri(): string {
//     return this.configService.get<string>('MONGODB_URI');
//   }

//   get arkeselApiKey(): string {
//     return this.configService.get<string>('ARKESEL_API_KEY');
//   }

//   get arkeselSenderId(): string {
//     return this.configService.get<string>('ARKESEL_SENDER_ID');
//   }
// }