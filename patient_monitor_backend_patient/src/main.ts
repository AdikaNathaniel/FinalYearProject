import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { Logger, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { AppModule } from './app.module';
import { TransformationInterceptor } from './responseInterceptor';
import cookieParser from 'cookie-parser';
import { raw } from 'express';
import express from 'express';
import { join } from 'path';
import { HealthCheckService, MicroserviceHealthIndicator } from '@nestjs/terminus';
import * as crypto from 'crypto';

// Import SearchService class directly
// Update these import paths according to your project structure
import { SearchService } from './search/search.service'; // Adjust path as needed
// Alternative common paths you might need to check:
// import { SearchService } from './modules/search/search.service';
// import { SearchService } from './services/search.service';
// import { SearchService } from './search/services/search.service';

// Fix for crypto is not defined error
// @ts-ignore
global.crypto = crypto;

// Type definitions for better type safety
interface ElasticsearchClient {
  cluster: {
    health(): Promise<any>;
  };
  indices: {
    exists(params: { index: string }): Promise<any>;
    create(params: { index: string; body?: any }): Promise<any>;
  };
}

interface RedisClient {
  ping(): Promise<string>;
}

// Extended SearchService interface to ensure type safety
interface ISearchService {
  redisClient?: RedisClient;
  esClient?: ElasticsearchClient;
  createIndex?(indexName: string): Promise<void>;
}

const logger = new Logger('Bootstrap');

// Enhanced configuration with Elasticsearch and Redis settings
const CONFIG = {
  elasticsearch: {
    node: process.env.ELASTICSEARCH_HOST || 'http://localhost:9200',
    indices: {
      default: process.env.ELASTICSEARCH_DEFAULT_INDEX || 'default_index',
    },
    maxRetries: 5,
    requestTimeout: 60000,
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT, 10) || 6379,
    ttl: parseInt(process.env.REDIS_TTL, 10) || 3600, // 1 hour in seconds
  },
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
      ? [process.env.FRONTEND_URL || 'http://localhost:3000']
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
      await this.setupEmailFallbackMechanism();
      await this.checkSearchServicesConnection();
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
    logger.log(`Application is running on: ${await this.mainApp.getUrl()}`);
  }

 

  private async checkSearchServicesConnection() {
  try {
    let searchService: SearchService;
    
    try {
      searchService = this.mainApp.select(AppModule).get(SearchService, { strict: false });
      logger.log('✅ SearchService resolved successfully using class import');
    } catch (classError) {
      logger.warn('Class-based service resolution failed, trying fallback approaches...');
      
      try {
        searchService = this.mainApp.get(SearchService, { strict: false });
        logger.log('✅ SearchService resolved using fallback method');
      } catch (fallbackError) {
        try {
          searchService = this.mainApp.get('SearchService', { strict: false }) as SearchService;
          logger.log('✅ SearchService resolved using string token');
        } catch (stringError) {
          const errorMessage = 'All SearchService resolution methods failed. Cannot start application without search services.';
          logger.error(errorMessage);
          throw new Error(errorMessage);
        }
      }
    }

    if (!searchService) {
      throw new Error('SearchService resolved to null/undefined. Cannot start application.');
    }

    logger.log('🔍 Starting search services connection validation...');

    // Check Redis connection - make it mandatory
    const redisClient = (searchService as any).redisClient;
    if (redisClient) {
      try {
        await redisClient.ping();
        logger.log('✅ Redis connection established successfully');
      } catch (redisError) {
        logger.error('❌ Redis connection failed:', redisError.message);
        throw new Error(`Redis connection failed: ${redisError.message}`);
      }
    } else {
      throw new Error('Redis client not found in SearchService');
    }
    
    // Check Elasticsearch connection - make it mandatory
    const esClient = (searchService as any).esClient;
    if (esClient) {
      try {
        const esResponse = await esClient.cluster.health();
        const clusterStatus = esResponse.body?.status || esResponse.status || 'unknown';
        logger.log(`✅ Elasticsearch connection established successfully - Cluster status: ${clusterStatus}`);
        
        // Ensure default index exists
        const indexExists = await esClient.indices.exists({ 
          index: CONFIG.elasticsearch.indices.default 
        });
        
        const indexExistsResult = indexExists.body !== undefined ? indexExists.body : indexExists;
        
        if (!indexExistsResult) {
          logger.log(`📝 Creating default index: ${CONFIG.elasticsearch.indices.default}`);
          
          if (typeof (searchService as any).createIndex === 'function') {
            try {
              await (searchService as any).createIndex(CONFIG.elasticsearch.indices.default);
              logger.log(`✅ Default index created successfully: ${CONFIG.elasticsearch.indices.default}`);
            } catch (createError) {
              logger.error(`❌ Failed to create index using service method: ${createError.message}`);
              // Try direct client approach
              try {
                await esClient.indices.create({
                  index: CONFIG.elasticsearch.indices.default,
                  body: {
                    settings: {
                      number_of_shards: 1,
                      number_of_replicas: 0
                    }
                  }
                });
                logger.log(`✅ Default index created successfully using direct client: ${CONFIG.elasticsearch.indices.default}`);
              } catch (directCreateError) {
                logger.error(`❌ Failed to create index using direct client: ${directCreateError.message}`);
                throw new Error(`Failed to create Elasticsearch index: ${directCreateError.message}`);
              }
            }
          } else {
            logger.warn('⚠️  createIndex method not available on SearchService, trying direct client approach');
            try {
              await esClient.indices.create({
                index: CONFIG.elasticsearch.indices.default,
                body: {
                  settings: {
                    number_of_shards: 1,
                    number_of_replicas: 0
                  }
                }
              });
              logger.log(`✅ Default index created successfully: ${CONFIG.elasticsearch.indices.default}`);
            } catch (directCreateError) {
              logger.error(`❌ Failed to create index: ${directCreateError.message}`);
              throw new Error(`Failed to create Elasticsearch index: ${directCreateError.message}`);
            }
          }
        } else {
          logger.log(`✅ Default index already exists: ${CONFIG.elasticsearch.indices.default}`);
        }
      } catch (esError) {
        logger.error('❌ Elasticsearch connection failed:', esError.message);
        throw new Error(`Elasticsearch connection failed: ${esError.message}`);
      }
    } else {
      throw new Error('Elasticsearch client not found in SearchService');
    }

    logger.log('🏁 Search services connection validation completed');
    
  } catch (error) {
    logger.error('❌ Search services connection check failed:', error.message);
    logger.error('Application cannot start without search services');
    throw error; // Re-throw to stop application startup
  }
}


  private configureMainApplication() {
    const configService = this.mainApp.get(ConfigService);
    
    this.mainApp.enableCors({
      origin: configService.get('FRONTEND_URL') || CONFIG.cors.allowedOrigins,
      credentials: CONFIG.cors.credentials,
      methods: CONFIG.cors.methods,
      allowedHeaders: CONFIG.cors.allowedHeaders,
    });
    
    // Configure WebSocket adapter
    this.mainApp.useWebSocketAdapter(new IoAdapter(this.mainApp));
    
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
    try {
      const server = this.mainApp.getHttpAdapter().getInstance();
      const routes = server._router?.stack
        ?.filter((r: any) => r.route)
        ?.map((r: any) => ({
          method: Object.keys(r.route.methods).map(method => method.toUpperCase()).join(', '),
          path: r.route.path,
        })) || [];

      if (routes.length > 0) {
        logger.log('Registered Routes:');
        routes.forEach(route => logger.log(`${route.method} ${route.path}`));
      } else {
        logger.log('No routes found or routes not yet registered');
      }
    } catch (error) {
      logger.warn('Could not log application routes:', error.message);
    }
  }

  private async setupEmailFallbackMechanism() {
    try {
      logger.log('Setting up email fallback mechanism...');
      
      // Add fallback endpoint after app initialization
      const app = this.mainApp.getHttpAdapter().getInstance();
      
      app.post('/api/v1/emails/fallback', (req: any, res: any) => {
        if (this.inMemoryEmailQueue.length >= CONFIG.fallback.maxQueueSize) {
          return res.status(503).json({
            message: 'Email queue is full. Please try again later.',
            queueSize: this.inMemoryEmailQueue.length
          });
        }

        const emailData = req.body;
        logger.log(`Email fallback received: ${JSON.stringify(emailData)}`);
        
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
        logger.log(`Processing email from fallback queue: ${JSON.stringify(item.data)}`);
        // Add your email processing logic here
        processedItems.push(item);
      } catch (error) {
        item.retryCount++;
        if (item.retryCount >= CONFIG.fallback.maxRetries) {
          logger.error(`Max retries reached for email: ${JSON.stringify(item.data)}`);
          failedItems.push(item);
        } else {
          logger.warn(`Retry ${item.retryCount} failed for email: ${JSON.stringify(item.data)}`);
        }
      }
    }

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

  private logStartupComplete() {
    logger.log('=================================');
    logger.log('🚀 Application startup complete!');
    logger.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    logger.log(`Main API: http://localhost:${CONFIG.server.port}/${CONFIG.server.apiPrefix}`);
    logger.log(`Elasticsearch: ${CONFIG.elasticsearch.node}`);
    logger.log(`Redis: ${CONFIG.redis.host}:${CONFIG.redis.port}`);
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

export const handler = async (req: any, res: any) => {
  const appManager = new ApplicationManager();
  await appManager.initialize();
  return appManager.mainApp.getHttpAdapter().getInstance()(req, res);
};

async function bootstrap() {
  const appManager = new ApplicationManager();
  await appManager.initialize();
}

if (process.env.NODE_ENV !== 'production') {
  bootstrap().catch(err => {
    logger.error('Fatal error during initialization', err.stack);
    process.exit(1);
  });
}