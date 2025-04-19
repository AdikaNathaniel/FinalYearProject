import { Controller, Post, Put, Get, Body, Param, Res, HttpStatus } from '@nestjs/common';
import { Response } from 'express';
import { DeliveryService } from 'src/delivery/delivery.service';
import { Delivery } from 'src/shared/schema/delivery.schema';

@Controller('delivery')
export class DeliveryController {
  constructor(private readonly deliveryService: DeliveryService) {}

  @Post('create')
  async create(@Body() data: Partial<Delivery>) {
    return this.deliveryService.createDelivery(data);
  }

  @Put('update/:productName')
  async update(@Param('productName') productName: string, @Body('status') status: string, @Res() res: Response) {
    try {
      const updatedDelivery = await this.deliveryService.updateStatus(productName, status);

      if (!updatedDelivery) {
        return res.status(HttpStatus.NOT_FOUND).json({
          timestamps: new Date().toISOString(),
          statusCode: HttpStatus.NOT_FOUND,
          path: res.req.originalUrl,
          error: 'Delivery not found',
        });
      }

      return res.status(HttpStatus.OK).json({
        timestamps: new Date().toISOString(),
        statusCode: HttpStatus.OK,
        path: res.req.originalUrl,
        error: null,
        productName: updatedDelivery.productName,
        status: updatedDelivery.status,
      });
    } catch (error) {
      console.error('Update error:', {
        message: error.message,
        stack: error.stack,
      });
      return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        timestamps: new Date().toISOString(),
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        path: res.req.originalUrl,
        error: 'Internal Server Error',
        message: error.message || 'An unexpected error occurred',
      });
    }
  }

  @Get('status/:productName')
  async getStatus(@Param('productName') productName: string, @Res() res: Response) {
    const deliveryStatus = await this.deliveryService.getStatus(productName);

    if (!deliveryStatus) {
      return res.status(HttpStatus.NOT_FOUND).json({
        timestamps: new Date().toISOString(),
        statusCode: HttpStatus.NOT_FOUND,
        path: res.req.originalUrl,
        error: 'Not Found',
      });
    }

    return res.status(HttpStatus.OK).json({
      timestamps: new Date().toISOString(),
      statusCode: HttpStatus.OK,
      path: res.req.originalUrl,
      error: null,
      productName: deliveryStatus.productName,
      status: deliveryStatus.status,
    });
  }
}