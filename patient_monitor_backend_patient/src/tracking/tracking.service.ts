import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Tracking } from 'src/shared/schema/tracking.schema';

@Injectable()
export class TrackingService {
  constructor(@InjectModel(Tracking.name) private trackingModel: Model<Tracking>) {}

  async updateLocation(driverId: string, location: [number, number]) {
    return this.trackingModel.findOneAndUpdate(
      { driverId },
      { location, lastUpdated: new Date() },
      { new: true, upsert: true }
    );
  }

  async getLocation(driverId: string) {
    return this.trackingModel.findOne({ driverId });
  }
}