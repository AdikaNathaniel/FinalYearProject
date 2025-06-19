import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { TrackingService } from 'src/tracking/tracking.service';

@Controller('tracking')
export class TrackingController {
  constructor(private readonly trackingService: TrackingService) {}

  @Post('update')
  async updateLocation(@Body() body: { driverId: string; location: [number, number] }) {
    return this.trackingService.updateLocation(body.driverId, body.location);
  }

  @Get(':driverId')
  async getLocation(@Param('driverId') driverId: string) {
    return this.trackingService.getLocation(driverId);
  }
}