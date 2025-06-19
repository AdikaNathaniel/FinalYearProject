import { NestFactory } from '@nestjs/core';
// import { NotificationModule } from 'src/notification/notification.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { EmailModule } from 'src/email/email.module';
import { AppModule } from './app.module';
import config from 'config';
import { TransformationInterceptor } from './responseInterceptor';
import cookieParser from 'cookie-parser';
import { NextFunction, raw, Request, Response } from 'express';
import csurf from 'csurf';
import express from 'express';

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
// let notificationApp: any;
let emailMicroservice: any;

async function bootstrap() {
  if (!app) {
    try {
      app = await NestFactory.create(AppModule, { 
        rawBody: true,
        logger: ['error', 'warn', 'log'] 
      });

 

app.enableCors({
  origin: process.env.NODE_ENV === 'production'
    ? [process.env.FRONTEND_URL || 'http://localhost:3000']
    : [
        'http://localhost:3000',
        'http://localhost:60991',  // Add your Flutter app's port
        // You can also include a wider range if your port changes frequently:
        /^http:\/\/localhost:[0-9]+$/  // This will match any localhost port
      ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Role', 'X-XSRF-TOKEN']
});



// app.enableCors({
//   origin: true,  // Allows ANY origin in development (⚠️ Only for testing!)
//   credentials: true,
//   methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
//   allowedHeaders: ['Content-Type', 'Authorization', 'Role', 'X-XSRF-TOKEN']
// });



      app.use(express.json({ limit: '50mb' }));
      app.use(express.urlencoded({ extended: true, limit: '50mb' }));
      app.use(cookieParser());

      app.use('/api/v1/orders/webhook', raw({ type: '*/*' }));

      const prefix = process.env.API_PREFIX || 'api/v1';
      app.setGlobalPrefix(prefix);
      app.useGlobalInterceptors(new TransformationInterceptor());

      // Print the routes
      const server = app.getHttpAdapter().getInstance();

      const routes = server._router.stack
        .filter((r: any) => r.route) // only get the routes
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

      const port = process.env.PORT || 3100;
      await app.listen(port);
      
      console.log(`Server running on port ${port}`);
    } catch (error) {
      console.error('Bootstrap error:', error);
      throw error;
    }
  }

  // Bootstrapping the Notification Module
  // if (!notificationApp) {
  //   notificationApp = await NestFactory.create(NotificationModule);
  //   await notificationApp.listen(3001);
  //   console.log('Notification service running on port 3001');
  // }

  // Bootstrapping the Email Microservice
  if (!emailMicroservice) {
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