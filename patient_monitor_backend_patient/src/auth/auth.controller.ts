
import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { FaceAuthService } from '../face-auth/face-auth.service';
import { VerifyFaceDto } from 'src/users/dto/verify-face.dto';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private faceAuthService: FaceAuthService
  ) {}

  @Post('login')
  async faceLogin(@Body() verifyFaceDto: VerifyFaceDto) {
    const result = await this.faceAuthService.verifyFace(verifyFaceDto);
    if (!result) {
      return { success: false, message: 'Face not recognized' };
    }
    
    const token = await this.authService.login({
      userId: result.user.userId,
      username: result.user.username,
      role: result.user.role,
    });
    
    return { 
      success: true,
      access_token: token.access_token,
      user: {
        userId: result.user.userId,
        username: result.user.username,
        role: result.user.role,
      },
      distance: result.distance,
    };
  }
}