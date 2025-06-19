import { Injectable, Logger } from '@nestjs/common';
import * as faceapi from 'face-api.js';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Face } from 'src/shared/schema/face.schema';
import { existsSync, mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';
// Remove this line - it's not used in your code
// import * as tf from '@tensorflow/tfjs-node';
import { Canvas, Image, ImageData } from 'canvas';

// Patch nodejs environment to use canvas for face-api.js
const nodeCanvas = { Canvas, Image, ImageData };
// @ts-ignore
faceapi.env.monkeyPatch(nodeCanvas);

@Injectable()
export class FaceService {
  private readonly uploadDir = join(__dirname, '..', '..', 'uploads');
  private readonly logger = new Logger(FaceService.name);
  private modelsLoaded = false;

  constructor(@InjectModel(Face.name) private faceModel: Model<Face>) {
    this.ensureUploadsDirExists();
    this.loadModels().catch(err => {
      this.logger.error(`Failed to load face-api models: ${err.message}`);
    });
  }

  private ensureUploadsDirExists() {
    if (!existsSync(this.uploadDir)) {
      mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  private async loadModels() {
    if (this.modelsLoaded) return;
    
    try {
      const modelsPath = join(__dirname, '..', '..', 'models');
      
      this.logger.log(`Loading face-api models from: ${modelsPath}`);
      
      await faceapi.nets.ssdMobilenetv1.loadFromDisk(modelsPath);
      await faceapi.nets.faceLandmark68Net.loadFromDisk(modelsPath);
      await faceapi.nets.faceRecognitionNet.loadFromDisk(modelsPath);
      await faceapi.nets.ageGenderNet.loadFromDisk(modelsPath);
      
      this.modelsLoaded = true;
      this.logger.log('Face-api models loaded successfully');
    } catch (error) {
      this.modelsLoaded = false;
      this.logger.error(`Error loading face-api models: ${error.message}`);
      throw error;
    }
  }

  async saveImage(file: Express.Multer.File): Promise<string> {
    const filename = `${Date.now()}-${file.originalname}`;
    const filePath = join(this.uploadDir, filename);
    writeFileSync(filePath, file.buffer);
    return filename;
  }

  async createImageFromBuffer(buffer: Buffer): Promise<any> {
    return new Promise((resolve, reject) => {
      const img = new Image();
      
      img.onload = () => resolve(img);
      img.onerror = (err) => reject(new Error('Failed to load image'));
      
      // Set the source as a data URL
      img.src = `data:image/jpeg;base64,${buffer.toString('base64')}`;
    });
  }

  async registerFace(
    userId: string,
    imageBuffer: Buffer,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      // Ensure models are loaded
      if (!this.modelsLoaded) {
        await this.loadModels();
      }

      // Create image from buffer
      const img = await this.createImageFromBuffer(imageBuffer);
      
      // Detect faces
      const detections = await faceapi
        .detectAllFaces(img)
        .withFaceLandmarks()
        .withFaceDescriptors()
        .withAgeAndGender();

      if (detections.length === 0) {
        return { success: false, error: 'No faces detected in the image' };
      }

      const { descriptor, age, gender } = detections[0];
      
      // Save the image
      const imagePath = await this.saveImage({
        buffer: imageBuffer,
        originalname: `${userId}-${Date.now()}.jpg`,
      } as Express.Multer.File);

      // Save face data to database
      await this.faceModel.create({
        userId,
        descriptor: Array.from(descriptor),
        age,
        gender,
        imagePath,
      });

      return { success: true };
    } catch (error) {
      this.logger.error(`Error registering face: ${error.message}`);
      return { success: false, error: error.message };
    }
  }

  async detectFaces(imageBuffer: Buffer) {
    try {
      // Ensure models are loaded
      if (!this.modelsLoaded) {
        await this.loadModels();
      }

      // Create image from buffer
      const img = await this.createImageFromBuffer(imageBuffer);
      
      // Detect faces
      const detections = await faceapi
        .detectAllFaces(img)
        .withFaceLandmarks()
        .withFaceDescriptors()
        .withAgeAndGender();

      return detections.map((detection) => ({
        age: Math.round(detection.age),
        gender: detection.gender,
        genderProbability: detection.genderProbability,
        descriptor: Array.from(detection.descriptor),
      }));
    } catch (error) {
      this.logger.error(`Error detecting faces: ${error.message}`);
      throw new Error(`Face detection failed: ${error.message}`);
    }
  }

  async findMatchingFace(descriptor: number[]) {
    try {
      const faces = await this.faceModel.find().exec();
      
      if (faces.length === 0) {
        return null;
      }

      const labeledDescriptors = faces.map(
        (face) =>
          new faceapi.LabeledFaceDescriptors(face.userId, [
            new Float32Array(face.descriptor),
          ]),
      );

      const faceMatcher = new faceapi.FaceMatcher(
        labeledDescriptors,
        0.6, // Distance threshold
      );

      const bestMatch = faceMatcher.findBestMatch(new Float32Array(descriptor));
      
      return bestMatch.label !== 'unknown'
        ? { userId: bestMatch.label, confidence: bestMatch.distance }
        : null;
    } catch (error) {
      this.logger.error(`Error finding matching face: ${error.message}`);
      throw new Error(`Face matching failed: ${error.message}`);
    }
  }
}