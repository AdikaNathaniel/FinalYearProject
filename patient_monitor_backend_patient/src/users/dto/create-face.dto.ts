// src/face-recognition/dtos/face-detection.dto.ts
export class FaceDetectionDto {
  image: string;  // Base64 or file path
}

export class FaceDetectionResponse {
  faces: {
    age: number;
    gender: string;
    genderProbability: number;
    descriptor: number[];
  }[];
  match?: {
    userId: string;
    confidence: number;
  };
}