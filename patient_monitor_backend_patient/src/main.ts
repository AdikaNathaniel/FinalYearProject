import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { Logger, ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { NotificationModule } from './notification/notification.module';
import { EmailModule } from './email/email.module';
import { TransformationInterceptor } from './responseInterceptor';
import cookieParser from 'cookie-parser';
import { raw } from 'express';
import express from 'express';
import { join } from 'path';
import { HealthCheckService, MicroserviceHealthIndicator } from '@nestjs/terminus';

// Fix for crypto is not defined error
import * as crypto from 'crypto';
// @ts-ignore
global.crypto = crypto;

// Add TensorFlow.js Node.js bindings
// import '@tensorflow/tfjs-node';

const logger = new Logger('Bootstrap');

// Configuration constants
const CONFIG = {
  rabbitmq: {
    url: process.env.RABBITMQ_URL || 'amqp://localhost:5672',
    queue: 'email_queue',
    reconnectDelay: 5000,
    maxAttempts: 10,
    timeout: 10000,
  },
  server: {
    port: parseInt(process.env.PORT, 10) || 3000,
    notificationPort: 3001,
    apiPrefix: process.env.API_PREFIX || 'api/v1',
  },
  cors: {
    allowedOrigins: process.env.NODE_ENV === 'production'
      ? [process.env.FRONTEND_URL || '*']
      : true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Role', 'X-XSRF-TOKEN'],
  },
  fallback: {
    maxQueueSize: 1000,
    retryInterval: 60000, // 1 minute
    maxRetries: 5,
  },
  static: {
    profilePhotosPath: join(__dirname, '..', 'uploads', 'profile-photos'),
    profilePhotosRoute: '/profile-photos',
  }
};

class ApplicationManager {
  public mainApp: any;
  private notificationApp: any;
  private emailMicroservice: any;
  private reconnectAttempts = 0;
  private isShuttingDown = false;
  private inMemoryEmailQueue: Array<{
    data: any;
    timestamp: Date;
    retryCount: number;
  }> = [];
  private fallbackInterval: NodeJS.Timeout | null = null;

  async initialize() {
    try {
      await this.setupErrorHandlers();
      await this.initializeMainApplication();
      await this.initializeNotificationService();
      // await this.initializeEmailMicroservice();
      // await this.setupHealthChecks();
      await this.setupEmailFallbackMechanism();
      this.logStartupComplete();
    } catch (error) {
      logger.error('Initialization failed', error.stack);
      await this.gracefulShutdown(1);
    }
  }

  private async setupErrorHandlers() {
    process.on('unhandledRejection', (reason) => {
      logger.error('Unhandled Rejection:', reason);
    });

    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', error.stack);
      this.gracefulShutdown(1);
    });

    process.on('SIGTERM', () => this.gracefulShutdown(0));
    process.on('SIGINT', () => this.gracefulShutdown(0));
  }

  private async initializeMainApplication() {
    this.mainApp = await NestFactory.create(AppModule, {
      rawBody: true,
      logger: ['error', 'warn', 'log'],
    });

    this.configureMainApplication();
    await this.mainApp.listen(CONFIG.server.port);
    logger.log(`Main application running on port ${CONFIG.server.port}`);
  }

  private configureMainApplication() {
    // Apply CORS settings
    this.mainApp.enableCors(CONFIG.cors);
    
    // Configure middleware
    this.mainApp.use(express.json({ limit: '50mb' }));
    this.mainApp.use(express.urlencoded({ extended: true, limit: '50mb' }));
    this.mainApp.use(cookieParser());
    this.mainApp.use('/api/v1/orders/webhook', raw({ type: '*/*' }));
    
    // Set up static file serving for profile photos
    this.mainApp.use(CONFIG.static.profilePhotosRoute, express.static(CONFIG.static.profilePhotosPath));
    logger.log(`Static files configured: ${CONFIG.static.profilePhotosRoute} -> ${CONFIG.static.profilePhotosPath}`);

    // Set global prefix and interceptors
    this.mainApp.setGlobalPrefix(CONFIG.server.apiPrefix);
    this.mainApp.useGlobalInterceptors(new TransformationInterceptor());
    
    // Add validation pipe
    this.mainApp.useGlobalPipes(new ValidationPipe({ transform: true }));

    this.logApplicationRoutes();
  }

  private logApplicationRoutes() {
    const server = this.mainApp.getHttpAdapter().getInstance();
    const routes = server._router.stack
      .filter((r: any) => r.route)
      .map((r: any) => ({
        method: Object.keys(r.route.methods).map(method => method.toUpperCase()).join(', '),
        path: r.route.path,
      }));

    logger.log('Registered Routes:');
    routes.forEach(route => logger.log(`${route.method} ${route.path}`));
  }

  private async initializeNotificationService() {
    this.notificationApp = await NestFactory.create(NotificationModule);
    await this.notificationApp.listen(CONFIG.server.notificationPort);
    logger.log(`Notification service running on port ${CONFIG.server.notificationPort}`);
  }

  // private async initializeEmailMicroservice() {
  //   try {
  //     this.emailMicroservice = await this.createEmailMicroservice();
  //     await this.emailMicroservice.listen();
  //     logger.log('Email microservice successfully connected to RabbitMQ');
  //     this.startProcessingFallbackQueue();
  //   } catch (error) {
  //     logger.error('Initial RabbitMQ connection failed', error.stack);
  //     await this.handleRabbitMQReconnection();
  //   }
  // }

  private async createEmailMicroservice() {
    return await NestFactory.createMicroservice<MicroserviceOptions>(EmailModule, {
      transport: Transport.RMQ,
      options: {
        urls: [CONFIG.rabbitmq.url],
        queue: CONFIG.rabbitmq.queue,
        queueOptions: {
          durable: true,
        },
        socketOptions: {
          heartbeatIntervalInSeconds: 60,
          reconnectTimeInSeconds: 5,
        },
      },
    });
  }

// private async handleRabbitMQReconnection() {
//     while (this.reconnectAttempts < CONFIG.rabbitmq.maxAttempts && !this.isShuttingDown) {
//       this.reconnectAttempts++;
//       logger.warn(`Attempting to reconnect to RabbitMQ (Attempt ${this.reconnectAttempts}/${CONFIG.rabbitmq.maxAttempts})`);

//       try {
//         await new Promise(resolve => setTimeout(resolve, CONFIG.rabbitmq.reconnectDelay));
//         this.emailMicroservice = await this.createEmailMicroservice();
//         await this.emailMicroservice.listen();
//         logger.log('Successfully reconnected to RabbitMQ');
//         this.reconnectAttempts = 0;
//         this.startProcessingFallbackQueue();
//         return;
//       } catch (error) {
//         logger.error(`Reconnection attempt ${this.reconnectAttempts} failed: ${error.message}`);
//       }
//     }

//     if (!this.isShuttingDown) {
//       logger.error(`Max reconnection attempts (${CONFIG.rabbitmq.maxAttempts}) reached. Continuing without RabbitMQ.`);
//     }
//   }

  private async setupEmailFallbackMechanism() {
    try {
      logger.log('Setting up email fallback mechanism...');
      
      // Set up an endpoint to handle email requests when RabbitMQ is down
      this.mainApp.post('/api/v1/emails/fallback', (req, res) => {
        if (this.inMemoryEmailQueue.length >= CONFIG.fallback.maxQueueSize) {
          return res.status(503).json({
            message: 'Email queue is full. Please try again later.',
            queueSize: this.inMemoryEmailQueue.length
          });
        }

        const emailData = req.body;
        logger.log(`Email fallback received: ${JSON.stringify(emailData)}`);
        
        // Store the email request for later processing
        this.inMemoryEmailQueue.push({
          data: emailData,
          timestamp: new Date(),
          retryCount: 0
        });
        
        res.status(202).json({
          message: 'Email request accepted via fallback mechanism',
          queueSize: this.inMemoryEmailQueue.length
        });
      });

      // Start processing the fallback queue periodically
      this.fallbackInterval = setInterval(() => {
        this.processFallbackQueue().catch(error => {
          logger.error('Error processing fallback queue:', error);
        });
      }, CONFIG.fallback.retryInterval);

      logger.log('Email fallback mechanism setup complete');
    } catch (error) {
      logger.error('Failed to setup email fallback mechanism:', error);
    }
  }

  private async processFallbackQueue() {
    if (!this.emailMicroservice || this.inMemoryEmailQueue.length === 0) {
      return;
    }

    logger.log(`Processing fallback queue (${this.inMemoryEmailQueue.length} items)`);
    
    const processedItems = [];
    const failedItems = [];

    for (const item of this.inMemoryEmailQueue) {
      try {
        // Here you would normally send the email via your email microservice
        // For demonstration, we'll just log it
        logger.log(`Processing email from fallback queue: ${JSON.stringify(item.data)}`);
        
        // Simulate successful processing
        processedItems.push(item);
      } catch (error) {
        item.retryCount++;
        if (item.retryCount >= CONFIG.fallback.maxRetries) {
          logger.error(`Max retries reached for email: ${JSON.stringify(item.data)}`);
          failedItems.push(item);
        } else {
          // Keep the item in the queue for next retry
          logger.warn(`Retry ${item.retryCount} failed for email: ${JSON.stringify(item.data)}`);
        }
      }
    }

    // Remove processed and failed items from the queue
    this.inMemoryEmailQueue = this.inMemoryEmailQueue.filter(
      item => !processedItems.includes(item) && !failedItems.includes(item)
    );

    if (processedItems.length > 0) {
      logger.log(`Successfully processed ${processedItems.length} emails from fallback queue`);
    }
    if (failedItems.length > 0) {
      logger.error(`Failed to process ${failedItems.length} emails after max retries`);
    }
  }

  private startProcessingFallbackQueue() {
    if (this.inMemoryEmailQueue.length > 0) {
      logger.log(`RabbitMQ reconnected, processing ${this.inMemoryEmailQueue.length} queued emails`);
      this.processFallbackQueue().catch(error => {
        logger.error('Error processing fallback queue after reconnection:', error);
      });
    }
  }

  // private async setupHealthChecks() {
  //   if (!this.mainApp) return;

  //   try {
  //     const healthCheckService = this.mainApp.get(HealthCheckService);
  //     const microserviceHealth = this.mainApp.get(MicroserviceHealthIndicator);

  //     this.mainApp.get('/health', async (req, res) => {
  //       try {
  //         const result = await healthCheckService.check([
  //           async () => microserviceHealth.pingCheck('rabbitmq', {
  //             transport: Transport.RMQ,
  //             options: { urls: [CONFIG.rabbitmq.url] },
  //             timeout: CONFIG.rabbitmq.timeout,
  //           }),
  //         ]);
  //         res.status(200).json(result);
  //       } catch (error) {
  //         res.status(503).json({
  //           status: 'error',
  //           details: {
  //             rabbitmq: { status: 'down', error: error.message },
  //           },
  //         });
  //       }
  //     });
  //   } catch (error) {
  //     logger.warn('Failed to setup health checks:', error.message);
  //   }
  // }

  private logStartupComplete() {
    logger.log('=================================');
    logger.log('🚀 Application startup complete!');
    logger.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    logger.log(`Main API: http://localhost:${CONFIG.server.port}/${CONFIG.server.apiPrefix}`);
    logger.log(`Notification Service: http://localhost:${CONFIG.server.notificationPort}`);
    logger.log(`Static Profile Photos: http://localhost:${CONFIG.server.port}${CONFIG.static.profilePhotosRoute}`);
    logger.log('=================================');
  }

  private async gracefulShutdown(exitCode: number) {
    if (this.isShuttingDown) return;
    this.isShuttingDown = true;

    logger.log('Starting graceful shutdown...');

    const shutdownPromises = [];
    if (this.mainApp) shutdownPromises.push(this.mainApp.close());
    if (this.notificationApp) shutdownPromises.push(this.notificationApp.close());
    if (this.emailMicroservice) shutdownPromises.push(this.emailMicroservice.close());
    
    // Clean up intervals
    if (this.fallbackInterval) {
      clearInterval(this.fallbackInterval);
    }

    try {
      await Promise.allSettled(shutdownPromises);
      logger.log('Graceful shutdown complete');
    } catch (error) {
      logger.error('Error during shutdown:', error);
    } finally {
      process.exit(exitCode);
    }
  }
}

// Serverless handler
export const handler = async (req: any, res: any) => {
  const appManager = new ApplicationManager();
  await appManager.initialize();
  return appManager.mainApp.getHttpAdapter().getInstance()(req, res);
};

// Bootstrap function
async function bootstrap() {
  const appManager = new ApplicationManager();
  await appManager.initialize();
}

// Start application in non-production environment
if (process.env.NODE_ENV !== 'production') {
  bootstrap().catch(err => {
    logger.error('Fatal error during initialization', err.stack);
    process.exit(1);
  });
}