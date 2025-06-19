import { Injectable } from '@nestjs/common';
import axios, { AxiosInstance } from 'axios';

@Injectable()
export class HttpService {
  private readonly axiosInstance: AxiosInstance;
  private readonly arkeselApiKey = 'R0lBd2RtanJrd3lsdmhjV1lrR2s'; 
  private readonly arkeselSenderId = 'Awo)Pa'; // Hardcoded sender ID

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