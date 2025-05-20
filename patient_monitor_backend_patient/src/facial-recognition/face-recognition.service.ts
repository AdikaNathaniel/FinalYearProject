// src/face-recognition/services/face.service.ts
import { Injectable } from '@nestjs/common';
import * as faceapi from 'face-api.js';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Face } from 'src/shared/schema/face.schema';
import { FaceDetectionDto, FaceDetectionResponse } from 'src/users/dto/create-face.dto';
import { mkdirSync, existsSync, writeFileSync } from 'fs';
import { join } from 'path';

@Injectable()
export class FaceService {
  private readonly uploadDir = join(__dirname, '..', '..', 'uploads');

  constructor(@InjectModel(Face.name) private faceModel: Model<Face>) {
    this.loadModels();
    this.ensureUploadsDirExists();
  }

  private ensureUploadsDirExists() {
    if (!existsSync(this.uploadDir)) {
      mkdirSync(this.uploadDir, { recursive: true });
    }
  }

 
  private async loadModels() {
  const modelsPath = join(__dirname, '..', '..', 'models'); // Points to project-root/models
  await Promise.all([
    faceapi.nets.ssdMobilenetv1.loadFromDisk(modelsPath),
    faceapi.nets.faceLandmark68Net.loadFromDisk(modelsPath),
    faceapi.nets.faceRecognitionNet.loadFromDisk(modelsPath),
    faceapi.nets.ageGenderNet.loadFromDisk(modelsPath),
  ]);
}

  async saveImage(file: Express.Multer.File): Promise<string> {
    const filename = `${Date.now()}-${file.originalname}`;
    const filePath = join(this.uploadDir, filename);
    writeFileSync(filePath, file.buffer);
    return filename;
  }

  async registerFace(
    userId: string,
    imageBuffer: Buffer,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      // Use canvas to load image from buffer in Node.js
      const { Canvas, Image, ImageData } = require('canvas');
      const img = new Image();
      img.src = imageBuffer;
      const detections = await faceapi
        .detectAllFaces(img)
        .withFaceLandmarks()
        .withFaceDescriptors()
        .withAgeAndGender();

      if (detections.length === 0) {
        return { success: false, error: 'No faces detected' };
      }

      const { descriptor, age, gender } = detections[0];
      const imagePath = await this.saveImage({
        buffer: imageBuffer,
        originalname: `${userId}-${Date.now()}.jpg`,
      } as Express.Multer.File);

      await this.faceModel.create({
        userId,
        descriptor: Array.from(descriptor),
        age,
        gender,
        imagePath,
      });

      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async detectFaces(imageBuffer: Buffer) {
    const { Image } = require('canvas');
    const img = new Image();
    img.src = imageBuffer;
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
  }

  async findMatchingFace(descriptor: number[]) {
    const faces = await this.faceModel.find().exec();
    if (faces.length === 0) return null;

    const faceMatcher = new faceapi.FaceMatcher(
      faces.map(
        (face) =>
          new faceapi.LabeledFaceDescriptors(face.userId, [
            new Float32Array(face.descriptor),
          ]),
      ),
      0.6,
    );

    const bestMatch = faceMatcher.findBestMatch(new Float32Array(descriptor));
    return bestMatch.label !== 'unknown'
      ? { userId: bestMatch.label, confidence: bestMatch.distance }
      : null;
  }
}