import { NestFactory } from '@nestjs/core';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { ValidationPipe, Logger } from '@nestjs/common';
import cookieParser from 'cookie-parser';
import express, { raw } from 'express';
import { join } from 'path';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { TransformationInterceptor } from './responseInterceptor';
import * as crypto from 'crypto';

// Only assign global.crypto if it doesn't exist (modern Node has it read-only)
if (typeof (global as any).crypto === 'undefined') {
  (global as any).crypto = crypto;
}

const logger = new Logger('Bootstrap');

async function bootstrap() {
  const appManager = new ApplicationManager();
  try {
    await appManager.initialize();
    logger.log('🚀 Application bootstrap completed successfully!');
  } catch (err) {
    logger.error('❌ Fatal error during application bootstrap:', err.stack || err.message);
    process.exit(1); // Exit only if bootstrap fails
  }
}

// Call bootstrap unconditionally (production or development)
bootstrap();

// Optional serverless handler (kept for lambda style deployment)
export const handler = async (req: any, res: any) => {
  const appManager = new ApplicationManager();
  await appManager.initialize();
  return appManager.mainApp.getHttpAdapter().getInstance()(req, res);
};
