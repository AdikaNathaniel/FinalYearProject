import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { FaceAuthService } from '../face-auth/face-auth.service';
import { UserPayload } from './interfaces/user-payload.interface';

@Injectable()
export class AuthService {
  constructor(
    private faceAuthService: FaceAuthService,
    private jwtService: JwtService,
  ) {}

  async validateUser(userId: string) {
    return this.faceAuthService.findOne(userId);
  }

  async login(user: UserPayload) {
    const payload = { 
      username: user.username, 
      sub: user.userId, 
      role: user.role 
    };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }
}