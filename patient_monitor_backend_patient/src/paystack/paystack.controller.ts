// paystack.controller.ts
import { Controller, Post, Body, Query, Get } from '@nestjs/common';
import { PaystackService } from './paystack.service';

@Controller('paystack')
export class PaystackController {
  constructor(private readonly paystackService: PaystackService) {}

  @Post('initiate')
  async initiatePayment(
    @Body() body: { email: string; amount: number; channels?: string[] }
  ) {
    return await this.paystackService.initializeTransaction(body.email, body.amount, body.channels);
  }

  @Post('verify')
  async verifyPayment(@Query('reference') reference: string) {
    return await this.paystackService.verifyTransaction(reference);
  }

  @Get('transactions')
  async getTransactions(
    @Query('page') page = 1,
    @Query('perPage') perPage = 10,
    @Query('status') status = 'success'
  ) {
    return await this.paystackService.listTransactions(Number(page), Number(perPage), status);
  }
}
// Removed custom Get function; using NestJS's Get decorator instead.

