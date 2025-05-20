import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { FacialRecognitionController } from './face-recognition.controller';
import { FacialRecognitionService } from './face-recognition.service';
import { Face, FaceSchema } from 'src/shared/schema/face.schema';
import { MulterModule } from '@nestjs/platform-express';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Face.name, schema: FaceSchema }]),
    MulterModule.register({
      dest: './uploads',
    }),
  ],
  controllers: [FacialRecognitionController],
  providers: [FacialRecognitionService],
  exports: [FacialRecognitionService], // Export if you want to use the service in other modules
})
export class FacialRecognitionModule {}