// src/face-recognition/controllers/face.controller.ts
import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
  Body,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { FaceService } from './face-recognition.service';
import { FaceDetectionResponse } from 'src/users/dto/create-face.dto';

@Controller('face')
export class FaceController {
  constructor(private readonly faceService: FaceService) {}

  @Post('detect')
  @UseInterceptors(FileInterceptor('image'))
  async detectFaces(
    @UploadedFile() file: Express.Multer.File,
  ): Promise<FaceDetectionResponse> {
    const faces = await this.faceService.detectFaces(file.buffer);
    const match =
      faces.length > 0
        ? await this.faceService.findMatchingFace(faces[0].descriptor)
        : null;
    return { faces, match };
  }

  @Post('register')
  @UseInterceptors(FileInterceptor('image'))
  async registerFace(
    @UploadedFile() file: Express.Multer.File,
    @Body() { userId }: { userId: string },
  ) {
    return this.faceService.registerFace(userId, file.buffer);
  }
}