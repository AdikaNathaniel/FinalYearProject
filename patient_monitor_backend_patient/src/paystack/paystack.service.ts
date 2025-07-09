// paystack.service.ts
import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class PaystackService {
  private readonly BASE_URL = 'https://api.paystack.co';

  constructor() {}

  async initializeTransaction(email: string, amount: number, channels: string[] = []) {
    try {
      const response = await axios.post(
        `${this.BASE_URL}/transaction/initialize`,
        {
          email,
          amount, // in kobo or pesewas (i.e., GHS 50.00 = 5000)
          channels: channels.length > 0 ? channels : ['card', 'bank', 'ussd', 'mobile_money', 'qr', 'bank_transfer'],
          currency: 'GHS' // or 'NGN', 'ZAR'
        },
        {
          headers: {
            Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
            'Content-Type': 'application/json',
          },
        },
      );

      return response.data;
    } catch (error) {
      throw new HttpException(
        error.response?.data?.message || 'Paystack Error',
        error.response?.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async verifyTransaction(reference: string) {
    try {
      const response = await axios.get(
        `${this.BASE_URL}/transaction/verify/${reference}`,
        {
          headers: {
            Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
          },
        },
      );
      return response.data;
    } catch (error) {
      throw new HttpException(
        error.response?.data?.message || 'Verification Error',
        error.response?.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }


async listTransactions(page = 1000, perPage = 1000000, status = 'success') {
    try {
      const response = await axios.get(`${this.BASE_URL}/transaction`, {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
        params: {
          page,
          perPage,
          status, // optional: 'success', 'failed', etc.
        },
      });
      return response.data;
    } catch (error) {
      throw new HttpException(
        error.response?.data?.message || 'Failed to fetch transactions',
        error.response?.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }


}
