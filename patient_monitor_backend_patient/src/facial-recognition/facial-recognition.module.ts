// src/face-recognition/face-recognition.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { FaceController } from './face-recognition.controller';
import { FaceService } from './face-recognition.service';
import { Face, FaceSchema } from 'src/shared/schema/face.schema';

@Module({
  imports: [MongooseModule.forFeature([{ name: Face.name, schema: FaceSchema }])],
  controllers: [FaceController],
  providers: [FaceService],
})
export class FaceRecognitionModule {}