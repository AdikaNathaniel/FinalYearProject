import { Injectable } from '@nestjs/common';
import axios, { AxiosInstance } from 'axios';

@Injectable()
export class HttpService {
  private readonly axiosInstance: AxiosInstance;
  private readonly arkeselApiKey = 'TkxTbnJoQm5iY2l4YUpiVmxIb0o'; 
  private readonly arkeselSenderId = 'AwoaPa'; 

  constructor() {
    this.axiosInstance = axios.create({
      baseURL: 'https://sms.arkesel.com/api/v2',
      headers: {
        'api-key': this.arkeselApiKey,
        'Content-Type': 'application/json',
      },
    });
  }

  get senderId(): string {
    return this.arkeselSenderId;
  }

  async post<T>(url: string, data: any): Promise<T> {
    const response = await this.axiosInstance.post<T>(url, data);
    return response.data;
  }

  async get<T>(url: string): Promise<T> {
    const response = await this.axiosInstance.get<T>(url);
    return response.data;
  }
}