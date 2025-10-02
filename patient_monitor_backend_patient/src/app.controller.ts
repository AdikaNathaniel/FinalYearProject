// app.controller.ts
import { Controller, Get, Req } from '@nestjs/common';
import { Request } from 'express';
import { AppService } from './app.service';

// Define interface for Request with CSRF
interface CsrfRequest extends Request {
  csrfToken(): string;
}

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello() + 'Digizone backend service.....';
  }

  @Get('/test')
  getTest(): string {
    return this.appService.getTest();
  }

   @Get('csrf-token')
  getCsrfToken(@Req() req: CsrfRequest): any {
     const csrfToken = req.csrfToken();
   return {
       result: csrfToken,
    };
  }
  
}