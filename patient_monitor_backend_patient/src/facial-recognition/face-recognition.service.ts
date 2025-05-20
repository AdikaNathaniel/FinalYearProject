import { Injectable, OnModuleInit } from '@nestjs/common';
import { FaceData } from './interfaces/face-data.interface';
import { Model } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';
import { Face } from 'src/shared/schema/face.schema';
import * as fs from 'fs';
import * as path from 'path';
import * as canvas from 'canvas';

// Import TensorFlow.js directly
import * as tf from '@tensorflow/tfjs-core';
import '@tensorflow/tfjs-backend-cpu';

// Try a different import approach for face-api
// First, ensure you have proper canvas setup
const { Canvas, Image, ImageData } = canvas;
// Global registration for canvas (needed before face-api import)
global.Canvas = Canvas;
global.Image = Image as any;
global.ImageData = ImageData as any;

// Now import face-api - if ESM version doesn't work, try CommonJS version
import * as faceapi from '@vladmandic/face-api';

@Injectable()
export class FacialRecognitionService implements OnModuleInit {
  private modelsLoaded = false;
  private canvas: typeof canvas;

  constructor(@InjectModel(Face.name) private faceModel: Model<Face>) {
    this.canvas = canvas;
  }

  async onModuleInit() {
    await this.setupEnvironment();
    await this.loadModels();
  }

  private async setupEnvironment() {
    try {
      console.log('Setting up TensorFlow.js environment...');
      
      // Initialize the TensorFlow backend directly
      try {
        // Try to use CPU backend
        await tf.setBackend('cpu');
        await tf.ready();
        console.log('TensorFlow.js backend initialized:', tf.getBackend());
      } catch (err) {
        console.error('Error initializing TensorFlow backend:', err);
        // If that fails, just continue and hope for the best
      }

      // Canvas is already registered globally during import
      // But we'll add a fallback monkey patch just to be sure
      try {
        const { Canvas, Image, ImageData } = this.canvas;
        faceapi.env.monkeyPatch({
          Canvas: Canvas as any,
          Image: Image as any,
          ImageData: ImageData as any
        });
      } catch (err) {
        console.error('Warning: Could not monkey patch canvas:', err);
        // Continue anyway
      }
      
      console.log('Environment setup complete');
    } catch (error) {
      console.error('Error setting up environment:', error);
      throw error;
    }
  }

  private async downloadModelsIfNeeded() {
    const modelsPath = path.join(__dirname, 'models');
    
    // Create models directory if it doesn't exist
    if (!fs.existsSync(modelsPath)) {
      console.log('Models directory not found, creating...');
      fs.mkdirSync(modelsPath, { recursive: true });
    }
    
    // Check if model files exist
    const ssdMobilenetPath = path.join(modelsPath, 'ssd_mobilenetv1_model-weights_manifest.json');
    
    if (!fs.existsSync(ssdMobilenetPath)) {
      console.log('Model files not found, downloading from CDN...');
      
      try {
        // Load models from URI (this will download them)
        // await faceapi.nets.ssdMobilenetv1.loadFromUri('https://vladmandic.github.io/face-api/model/');
        // await faceapi.nets.faceLandmark68Net.loadFromUri('https://vladmandic.github.io/face-api/model/');
        // await faceapi.nets.faceRecognitionNet.loadFromUri('https://vladmandic.github.io/face-api/model/');
        // await faceapi.nets.ageGenderNet.loadFromUri('https://vladmandic.github.io/face-api/model/');


await faceapi.nets.ssdMobilenetv1.loadFromUri('/face recognition/models/');
await faceapi.nets.faceLandmark68Net.loadFromUri('/face recognition/models/');
await faceapi.nets.faceRecognitionNet.loadFromUri('/face recognition/models/');
await faceapi.nets.ageGenderNet.loadFromUri('/face recognition/models/');

        
        // Models loaded from URI; skipping save to disk as saveToDisk is not available
        console.log('Models loaded successfully');
      } catch (error) {
        console.error('Error downloading models:', error);
        throw error;
      }
    } else {
      console.log('Model files found, skipping download');
    }
  }

  private async loadModels() {
    try {
      // Check if models need to be downloaded
      await this.downloadModelsIfNeeded();
      
      // Load models from disk
      const modelsPath = path.join(__dirname, 'models');
      console.log('Loading face-api models from:', modelsPath);
      
      await Promise.all([
        faceapi.nets.ssdMobilenetv1.loadFromDisk(modelsPath),
        faceapi.nets.faceLandmark68Net.loadFromDisk(modelsPath),
        faceapi.nets.faceRecognitionNet.loadFromDisk(modelsPath),
        faceapi.nets.ageGenderNet.loadFromDisk(modelsPath),
      ]);
      
      this.modelsLoaded = true;
      console.log('Face API models loaded successfully');
    } catch (error) {
      console.error('Error loading face-api models:', error);
      throw error;
    }
  }

  private async ensureModelsLoaded() {
    if (!this.modelsLoaded) {
      console.log('Models not loaded yet, waiting...');
      await new Promise(resolve => setTimeout(resolve, 1000));
      return this.ensureModelsLoaded();
    }
    return true;
  }

  async processImage(imageBuffer: Buffer): Promise<FaceData[]> {
    await this.ensureModelsLoaded();

    try {
      // Create canvas image from buffer
      const img = await this.canvas.loadImage(imageBuffer);
      
      // Run face detection with all options
      const detections = await faceapi
        .detectAllFaces(img as any)
        .withFaceLandmarks()
        .withFaceDescriptors()
        .withAgeAndGender();

      // Map detections to our FaceData format
      return detections.map(detection => ({
        descriptor: Array.from(detection.descriptor),
        age: detection.age,
        gender: detection.gender,
        genderProbability: detection.genderProbability,
        detection: {
          box: {
            x: detection.detection.box.x,
            y: detection.detection.box.y,
            width: detection.detection.box.width,
            height: detection.detection.box.height
          },
          score: detection.detection.score
        }
      }));
    } catch (error) {
      console.error('Error processing image:', error);
      throw error;
    }
  }

  async saveFaceDescriptor(userId: string, faceData: FaceData) {
    try {
      const face = new this.faceModel({
        userId,
        descriptor: faceData.descriptor,
        age: faceData.age,
        gender: faceData.gender,
        genderProbability: faceData.genderProbability,
      });
      return await face.save();
    } catch (error) {
      console.error('Error saving face descriptor:', error);
      throw error;
    }
  }

  async recognizeFace(descriptor: Float32Array | number[]): Promise<{ userId: string; distance: number } | null> {
    try {
      const faces = await this.faceModel.find().exec();
      if (faces.length === 0) return null;

      // Create labeled face descriptors from stored faces
      const labeledFaceDescriptors = faces.map(face => {
        // Ensure the descriptor is a Float32Array as required by face-api
        const faceDescriptor = Array.isArray(face.descriptor) 
          ? new Float32Array(face.descriptor) 
          : face.descriptor;
          
        return new faceapi.LabeledFaceDescriptors(
          face.userId, 
          [faceDescriptor]
        );
      });

      // Create a face matcher with the labeled descriptors
      const faceMatcher = new faceapi.FaceMatcher(labeledFaceDescriptors);

      // Ensure input descriptor is Float32Array
      const inputDescriptor = Array.isArray(descriptor) 
        ? new Float32Array(descriptor) 
        : descriptor;

      // Find the best match
      const bestMatch = faceMatcher.findBestMatch(inputDescriptor);
      
      // Return match if confidence is high enough
      if (bestMatch.label !== 'unknown' && bestMatch.distance < 0.6) {
        return { userId: bestMatch.label, distance: bestMatch.distance };
      }
      
      return null;
    } catch (error) {
      console.error('Error recognizing face:', error);
      throw error;
    }
  }

  async compareWithReferenceImages(imageBuffer: Buffer): Promise<any> {
    await this.ensureModelsLoaded();

    try {
      // Load and process input image
      const img = await this.canvas.loadImage(imageBuffer);
      const faceDetectionResults = await faceapi
        .detectAllFaces(img as any)
        .withFaceLandmarks()
        .withFaceDescriptors();

      // Check if any face was detected
      if (!faceDetectionResults.length) {
        return { error: 'No face detected in the input image' };
      }

      const inputDescriptor = faceDetectionResults[0].descriptor;

      // Load reference images
      const refImagesPath = path.join(__dirname, 'images');
      
      // Create images directory if it doesn't exist
      if (!fs.existsSync(refImagesPath)) {
        fs.mkdirSync(refImagesPath, { recursive: true });
        return { message: 'Reference images directory created. Please add reference images.' };
      }
      
      const refImageFiles = fs.readdirSync(refImagesPath);
      
      if (refImageFiles.length === 0) {
        return { message: 'No reference images found. Please add reference images.' };
      }

      const results = [];
      
      // Process each reference image
      for (const file of refImageFiles) {
        try {
          const refImagePath = path.join(refImagesPath, file);
          const refImage = await this.canvas.loadImage(refImagePath);
          const refDetectionResults = await faceapi
            .detectAllFaces(refImage as any)
            .withFaceLandmarks()
            .withFaceDescriptors();

          if (refDetectionResults.length > 0) {
            const refDescriptor = refDetectionResults[0].descriptor;
            const distance = faceapi.euclideanDistance(inputDescriptor, refDescriptor);
            
            results.push({
              image: file,
              distance,
              match: distance < 0.6
            });
          } else {
            results.push({
              image: file,
              error: 'No face detected in reference image'
            });
          }
        } catch (err) {
          console.error(`Error processing reference image ${file}:`, err);
          results.push({
            image: file,
            error: 'Failed to process image'
          });
        }
      }

      return results;
    } catch (error) {
      console.error('Error comparing with reference images:', error);
      throw error;
    }
  }
}