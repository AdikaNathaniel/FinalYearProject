import { Controller, Post, Body, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { FacialRecognitionService } from './face-recognition.service';
import { ProcessImageDto } from 'src/users/dto/process-image.dto';
import { diskStorage } from 'multer';
import * as path from 'path';

@Controller('face')
export class FacialRecognitionController {
  constructor(private readonly facialRecognitionService: FacialRecognitionService) {}

  @Post('process')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: diskStorage({
        destination: './uploads',
        filename: (req, file, cb) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = path.extname(file.originalname);
          cb(null, `${uniqueSuffix}${ext}`);
        },
      }),
    }),
  )
  async processImage(@UploadedFile() file: Express.Multer.File, @Body() body: ProcessImageDto) {
    const fs = await import('fs/promises');
    const imageBuffer = await fs.readFile(file.path);
    const faceData = await this.facialRecognitionService.processImage(imageBuffer);
    
    if (faceData.length === 0) {
      return { success: false, message: 'No faces detected' };
    }

    // Compare with reference images
    const comparisonResults = await this.facialRecognitionService.compareWithReferenceImages(imageBuffer);
    
    // Save the first detected face (you can modify this as needed)
    const mainFace = faceData[0];
    await this.facialRecognitionService.saveFaceDescriptor(body.userId || 'unknown', mainFace);

    // Check if any reference image matched
    const matchedImage = comparisonResults.find(result => result.match);

    return {
      success: true,
      faceData: {
        age: mainFace.age,
        gender: mainFace.gender,
        genderProbability: mainFace.genderProbability,
      },
      comparisonResults,
      recognition: matchedImage ? {
        status: 'Login Successful',
        matchedImage: matchedImage.image,
        confidence: (1 - matchedImage.distance) * 100
      } : {
        status: 'No match found',
      }
    };
  }

  @Post('process-base64')
  async processBase64Image(@Body() body: ProcessImageDto) {
    const base64Data = body.image.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');
    
    const faceData = await this.facialRecognitionService.processImage(buffer);
    
    if (faceData.length === 0) {
      return { success: false, message: 'No faces detected' };
    }

    // Compare with reference images
    const comparisonResults = await this.facialRecognitionService.compareWithReferenceImages(buffer);
    
    // Save the first detected face
    const mainFace = faceData[0];
    await this.facialRecognitionService.saveFaceDescriptor(body.userId || 'unknown', mainFace);

    // Check if any reference image matched
    const matchedImage = comparisonResults.find(result => result.match);

    return {
      success: true,
      faceData: {
        age: mainFace.age,
        gender: mainFace.gender,
        genderProbability: mainFace.genderProbability,
      },
      comparisonResults,
      recognition: matchedImage ? {
        status: 'Login Successful',
        matchedImage: matchedImage.image,
        confidence: (1 - matchedImage.distance) * 100
      } : {
        status: 'No match found',
      }
    };
  }
}