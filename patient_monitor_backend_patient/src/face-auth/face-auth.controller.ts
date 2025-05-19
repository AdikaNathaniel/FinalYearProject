import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { FaceAuthService } from './face-auth.service';
import { CreateFaceAuthDto } from 'src/users/dto/create-face-auth.dto';
import { VerifyFaceDto } from 'src/users/dto/verify-face.dto';

@Controller('face-auth')
export class FaceAuthController {
  constructor(private readonly faceAuthService: FaceAuthService) {}

  @Post()
  create(@Body() createFaceAuthDto: CreateFaceAuthDto) {
    return this.faceAuthService.create(createFaceAuthDto);
  }

  @Get()
  findAll() {
    return this.faceAuthService.findAll();
  }

  @Get('descriptors')
  getAllFaceDescriptors() {
    return this.faceAuthService.getAllFaceDescriptors();
  }

  @Post('verify')
  verifyFace(@Body() verifyFaceDto: VerifyFaceDto) {
    return this.faceAuthService.verifyFace(verifyFaceDto);
  }

  @Get(':userId')
  findOne(@Param('userId') userId: string) {
    return this.faceAuthService.findOne(userId);
  }

  @Delete(':userId')
  remove(@Param('userId') userId: string) {
    return this.faceAuthService.remove(userId);
  }
}