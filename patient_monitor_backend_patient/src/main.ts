import { NestFactory } from '@nestjs/core';
import { NotificationModule } from 'src/notification/notification.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { EmailModule } from 'src/email/email.module';
import { AppModule } from './app.module';
import { TransformationInterceptor } from './responseInterceptor';
import cookieParser from 'cookie-parser';
import { NextFunction, raw, Request, Response } from 'express';
import csurf from 'csurf';
import express from 'express';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

const ROOT_IGNORED_PATHS = [
  '/api/v1/orders/webhook',
  '/api/v1/users',
  '/api/v1/users/login',
  '/api/v1/products',
  '/api/v1/products/*/reviews',
  '/api/v1/products/*/reviews/*',
  '/api/v1/orders/Checkout',
  '/api/v1/products/update-product*'
];

function isPathIgnored(path: string): boolean {
  return ROOT_IGNORED_PATHS.some(pattern => {
    const regexPattern = pattern
      .replace(/\*/g, '[^/]+')
      .replace(/\//g, '\\/');
    const regex = new RegExp(`^${regexPattern}$`);
    return regex.test(path);
  });
}

let app: any;
let notificationApp: any;
let emailMicroservice: any;

async function bootstrap() {
  if (!app) {
    try {
      app = await NestFactory.create(AppModule, { 
        rawBody: true,
        logger: ['error', 'warn', 'log'] 
      });

      // Swagger configuration for Pregnancy Health Analytics API
      const swaggerConfig = new DocumentBuilder()
        .setTitle('Pregnancy Health Analytics API')
        .setDescription('API for analyzing pregnancy health data with LangChain')
        .setVersion('1.0')
        .addTag('health-analytics')
        .build();
      const document = SwaggerModule.createDocument(app, swaggerConfig);
      SwaggerModule.setup('api-docs', app, document);

      app.enableCors({
        origin: process.env.NODE_ENV === 'production'
          ? [process.env.FRONTEND_URL || '*']
          : true,
        credentials: true,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'Role', 'X-XSRF-TOKEN']
      });

      app.use(express.json({ limit: '50mb' }));
      app.use(express.urlencoded({ extended: true, limit: '50mb' }));
      app.use(cookieParser());

      app.use('/api/v1/orders/webhook', raw({ type: '*/*' }));

      const prefix = process.env.API_PREFIX || 'api/v1';
      app.setGlobalPrefix(prefix);
      app.useGlobalInterceptors(new TransformationInterceptor());

      const port = process.env.PORT || 3100;
      await app.listen(port);
      
      // Try to print routes only after the app is fully initialized
      try {
        const server = app.getHttpAdapter().getInstance();
        // Check if server and router exist before trying to access stack
        if (server && server._router && server._router.stack) {
          const routes = server._router.stack
            .filter((r: any) => r.route)
            .map((r: any) => {
              return {
                method: Object.keys(r.route.methods).map(method => method.toUpperCase()).join(', '),
                path: r.route.path,
              };
            });

          console.log('Registered Routes:');
          routes.forEach(route => {
            console.log(`${route.method} ${route.path}`);
          });
        } else {
          console.log('Routes information not available at this stage');
        }
      } catch (routeError) {
        console.warn('Could not print routes:', routeError.message);
      }
      
      console.log(`Server running on port ${port}`);
      console.log(`Swagger documentation available at http://localhost:${port}/api-docs`);
    } catch (error) {
      console.error('Bootstrap error:', error);
      throw error;
    }
  }

  // Bootstrapping the Notification Module
  if (!notificationApp) {
    try {
      notificationApp = await NestFactory.create(NotificationModule);
      await notificationApp.listen(3001);
      console.log('Notification service running on port 3001');
    } catch (error) {
      console.error('Notification service error:', error);
      // Continue execution even if notification service fails
    }
  }

  // Bootstrapping the Email Microservice
  if (!emailMicroservice) {
    try {
      emailMicroservice = await NestFactory.createMicroservice<MicroserviceOptions>(
        EmailModule,
        {
          transport: Transport.RMQ,
          options: {
            urls: [process.env.RABBITMQ_URL || 'amqp://localhost:5672'],
            queue: 'email_queue',
            queueOptions: {
              durable: true,
            },
          },
        },
      );
      await emailMicroservice.listen();
      console.log('Email microservice is listening for messages');
    } catch (error) {
      console.error('Email microservice error:', error);
      // Continue execution even if email service fails
    }
  }

  return app;
}

// Serverless handler
export const handler = async (req: any, res: any) => {
  const server = await bootstrap();
  return server.getHttpAdapter().getInstance()(req, res);
};

// Start server normally in development
if (process.env.NODE_ENV !== 'production') {
  bootstrap();
}