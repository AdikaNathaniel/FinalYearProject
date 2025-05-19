import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { FaceAuth, FaceAuthDocument } from 'src/shared/schema/face-auth.schema';
import { CreateFaceAuthDto } from 'src/users/dto/create-face-auth.dto';
import { VerifyFaceDto } from 'src/users/dto/verify-face.dto';
import { calculateFaceDistance } from 'src/common/utils/face-distance.util';

@Injectable()
export class FaceAuthService {
  constructor(
    @InjectModel(FaceAuth.name) private faceAuthModel: Model<FaceAuthDocument>,
  ) {}

  async create(createFaceAuthDto: CreateFaceAuthDto): Promise<FaceAuth> {
    const createdFaceAuth = new this.faceAuthModel(createFaceAuthDto);
    return createdFaceAuth.save();
  }

  async findAll(): Promise<FaceAuth[]> {
    return this.faceAuthModel.find().exec();
  }

  async findOne(userId: string): Promise<FaceAuth> {
    return this.faceAuthModel.findOne({ userId }).exec();
  }

  async getAllFaceDescriptors() {
    return this.faceAuthModel.find().select('userId username role faceDescriptor -_id').exec();
  }

  async verifyFace(verifyFaceDto: VerifyFaceDto): Promise<{ user: FaceAuth; distance: number } | null> {
    const users = await this.faceAuthModel.find().exec();
    
    let minDistance = Infinity;
    let matchedUser: FaceAuth = null;

    for (const user of users) {
      const distance = calculateFaceDistance(user.faceDescriptor, verifyFaceDto.descriptor);
      if (distance < minDistance && distance < 0.6) { // Threshold of 0.6
        minDistance = distance;
        matchedUser = user;
      }
    }

    return matchedUser ? { user: matchedUser, distance: minDistance } : null;
  }

  async remove(userId: string): Promise<void> {
    await this.faceAuthModel.deleteOne({ userId }).exec();
  }
}