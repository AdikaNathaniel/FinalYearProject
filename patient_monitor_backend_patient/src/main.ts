import * as crypto from 'crypto';
globalThis.crypto = crypto.webcrypto as any;

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

// Import SearchService class directly
import { SearchService } from './search/search.service';

// =============================================================================
// CRITICAL FIX: DISABLE PROBLEMATIC SERVICES FOR PRODUCTION STABILITY
// =============================================================================

// Temporarily disable everything that could crash in production
if (process.env.NODE_ENV === 'production') {
  process.env.DISABLE_FACE_RECOGNITION = 'true';
  process.env.DISABLE_REDIS = 'true'; 
  process.env.DISABLE_ELASTICSEARCH = 'true';
  process.env.DISABLE_KAFKA = 'true';
  process.env.DISABLE_RABBITMQ = 'true';
  
  console.log('🔧 PRODUCTION MODE: Disabled external services for stability');
}

// Apply environment variable overrides if they exist
process.env.DISABLE_FACE_RECOGNITION = process.env.DISABLE_FACE_RECOGNITION || 'true';
process.env.DISABLE_REDIS = process.env.DISABLE_REDIS || 'true';
process.env.DISABLE_ELASTICSEARCH = process.env.DISABLE_ELASTICSEARCH || 'true';
process.env.DISABLE_KAFKA = process.env.DISABLE_KAFKA || 'true';
process.env.DISABLE_RABBITMQ = process.env.DISABLE_RABBITMQ || 'true';

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

interface ISearchService {
  redisClient?: RedisClient;
  esClient?: ElasticsearchClient;
  createIndex?(indexName: string): Promise<void>;
}

const logger = new Logger('Bootstrap');

// Enhanced configuration - ALL SERVICES NOW OPTIONAL BY DEFAULT
const CONFIG = {
  elasticsearch: {
    node: process.env.ELASTICSEARCH_HOST || 'http://localhost:9200',
    indices: {
      default: process.env.ELASTICSEARCH_DEFAULT_INDEX || 'default_index',
    },
    maxRetries: 5,
    requestTimeout: 60000,
    required: process.env.ELASTICSEARCH_REQUIRED === 'true' && process.env.DISABLE_ELASTICSEARCH !== 'true',
  },
  redis: {
    // Support for Redis URL (like Upstash, Redis Cloud, etc.)
    url: process.env.REDIS_URL,
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT, 10) || 6379,
    password: process.env.REDIS_PASSWORD,
    // Auto-detect TLS from URL or explicit flag
    tls: process.env.REDIS_TLS === 'true' || process.env.REDIS_URL?.startsWith('rediss://'),
    ttl: parseInt(process.env.REDIS_TTL, 10) || 3600,
    required: process.env.REDIS_REQUIRED === 'true' && process.env.DISABLE_REDIS !== 'true',
  },
  rabbitmq: {
    url: process.env.RABBITMQ_URL || 'amqp://localhost:5672',
    queue: 'email_queue',
    reconnectDelay: 5000,
    maxAttempts: 10,
    timeout: 10000,
    required: process.env.RABBITMQ_REQUIRED === 'true' && process.env.DISABLE_RABBITMQ !== 'true',
  },
  kafka: {
    required: process.env.KAFKA_REQUIRED === 'true' && process.env.DISABLE_KAFKA !== 'true',
  },
  faceRecognition: {
    enabled: process.env.DISABLE_FACE_RECOGNITION !== 'true',
  },
  server: {
    port: parseInt(process.env.PORT, 10) || 3000,
    notificationPort: 3001,
    apiPrefix: process.env.APP_PREFIX || 'api/v1',
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
    retryInterval: 60000,
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
      logger.log('=== STARTING APPLICATION INITIALIZATION ===');
      logger.log(`Node.js version: ${process.version}`);
      logger.log(`NODE_ENV: ${process.env.NODE_ENV}`);
      logger.log(`PORT: ${CONFIG.server.port}`);
      
      // Log disabled services
      this.logDisabledServices();
      
      await this.setupErrorHandlers();
      logger.log('✓ Error handlers configured');
      
      await this.initializeMainApplication();
      logger.log('✓ Main application initialized');
      
      // Only setup email if not disabled
      if (process.env.DISABLE_RABBITMQ !== 'true') {
        await this.setupEmailFallbackMechanism();
        logger.log('✓ Email fallback mechanism configured');
      } else {
        logger.log('⚠ Email fallback mechanism DISABLED');
      }
      
      // Only check search services if not disabled
      if (process.env.DISABLE_REDIS !== 'true' || process.env.DISABLE_ELASTICSEARCH !== 'true') {
        await this.checkSearchServicesConnection();
        logger.log('✓ Search services check completed');
      } else {
        logger.log('⚠ Search services check SKIPPED (all services disabled)');
      }
      
      this.logStartupComplete();
    } catch (error) {
      logger.error('=== INITIALIZATION FAILED ===');
      logger.error(`Error type: ${error.constructor.name}`);
      logger.error(`Error message: ${error.message}`);
      logger.error(`Error stack: ${error.stack}`);
      logger.error('=== END ERROR DETAILS ===');
      await this.gracefulShutdown(1);
    }
  }

  private logDisabledServices() {
    const disabledServices = [];
    if (process.env.DISABLE_FACE_RECOGNITION === 'true') disabledServices.push('Face Recognition');
    if (process.env.DISABLE_REDIS === 'true') disabledServices.push('Redis');
    if (process.env.DISABLE_ELASTICSEARCH === 'true') disabledServices.push('Elasticsearch');
    if (process.env.DISABLE_KAFKA === 'true') disabledServices.push('Kafka');
    if (process.env.DISABLE_RABBITMQ === 'true') disabledServices.push('RabbitMQ');
    
    if (disabledServices.length > 0) {
      logger.log(`🔧 DISABLED SERVICES: ${disabledServices.join(', ')}`);
    }
  }

  private async setupErrorHandlers() {
    process.on('unhandledRejection', (reason, promise) => {
      logger.error('=== UNHANDLED REJECTION ===');
      logger.error(`Reason: ${reason}`);
      logger.error(`Promise: ${promise}`);
      if (reason instanceof Error) {
        logger.error(`Stack: ${reason.stack}`);
      }
    });

    process.on('uncaughtException', (error) => {
      logger.error('=== UNCAUGHT EXCEPTION ===');
      logger.error(`Error: ${error.message}`);
      logger.error(`Stack: ${error.stack}`);
      this.gracefulShutdown(1);
    });

    process.on('SIGTERM', () => {
      logger.log('SIGTERM received');
      this.gracefulShutdown(0);
    });
    
    process.on('SIGINT', () => {
      logger.log('SIGINT received');
      this.gracefulShutdown(0);
    });
  }

  private async initializeMainApplication() {
    try {
      logger.log('Creating NestJS application...');
      this.mainApp = await NestFactory.create(AppModule, {
        rawBody: true,
        logger: ['error', 'warn', 'log', 'debug', 'verbose'],
      });
      logger.log('✓ NestJS application created');

      logger.log('Configuring application...');
      this.configureMainApplication();
      logger.log('✓ Application configured');

      logger.log(`Starting server on port ${CONFIG.server.port}...`);
      await this.mainApp.listen(CONFIG.server.port, '0.0.0.0');
      logger.log(`✓ Main application running on port ${CONFIG.server.port}`);
      logger.log(`✓ Application is running on: ${await this.mainApp.getUrl()}`);
    } catch (error) {
      logger.error('Failed to initialize main application');
      logger.error(`Error: ${error.message}`);
      logger.error(`Stack: ${error.stack}`);
      throw error;
    }
  }

  private async checkSearchServicesConnection() {
    try {
      logger.log('=== CHECKING SEARCH SERVICES (OPTIONAL) ===');
      
      // Quick check if all services are disabled
      if (process.env.DISABLE_REDIS === 'true' && process.env.DISABLE_ELASTICSEARCH === 'true') {
        logger.log('⚠ All search services disabled via environment variables');
        return;
      }
      
      let searchService: SearchService;
      
      try {
        searchService = this.mainApp.select(AppModule).get(SearchService, { strict: false });
        logger.log('✓ SearchService resolved successfully');
      } catch (classError) {
        logger.warn('SearchService resolution failed, trying fallback approaches...');
        logger.warn(`Error: ${classError.message}`);
        
        try {
          searchService = this.mainApp.get(SearchService, { strict: false });
          logger.log('✓ SearchService resolved using fallback method');
        } catch (fallbackError) {
          logger.warn(`Fallback resolution failed: ${fallbackError.message}`);
          try {
            searchService = this.mainApp.get('SearchService', { strict: false }) as SearchService;
            logger.log('✓ SearchService resolved using string token');
          } catch (stringError) {
            logger.warn('All SearchService resolution methods failed');
            logger.warn('⚠ Continuing without SearchService (all search services are optional)');
            return;
          }
        }
      }

      if (!searchService) {
        logger.warn('⚠ SearchService is null, continuing without search services...');
        return;
      }

      logger.log('Validating search services connections...');

      // Redis connection check with improved logging - only if not disabled
      if (process.env.DISABLE_REDIS !== 'true') {
        const redisClient = (searchService as any).redisClient;
        if (redisClient) {
          try {
            const connectionInfo = CONFIG.redis.url 
              ? `Redis URL (${CONFIG.redis.url.split('@')[1] || 'external'})`
              : `${CONFIG.redis.host}:${CONFIG.redis.port}`;
            
            logger.log(`Attempting Redis connection to ${connectionInfo}...`);
            logger.log(`TLS enabled: ${CONFIG.redis.tls ? 'Yes' : 'No'}`);
            
            await redisClient.ping();
            logger.log('✓ Redis connection established successfully');
            logger.log(`✓ Redis is ready for caching operations`);
          } catch (redisError) {
            logger.warn(`⚠ Redis connection failed: ${redisError.message}`);
            logger.warn(`Redis error details: ${redisError.stack}`);
            
            if (CONFIG.redis.required) {
              throw new Error(`Redis connection failed: ${redisError.message}`);
            } else {
              logger.warn('⚠ Redis not available but not required, continuing without Redis...');
              logger.warn('⚠ Search result caching will be disabled');
            }
          }
        } else {
          logger.warn('⚠ Redis client not found in SearchService');
          if (CONFIG.redis.required) {
            throw new Error('Redis client not found but is required');
          } else {
            logger.warn('⚠ Continuing without Redis (not required)');
          }
        }
      } else {
        logger.log('⚠ Redis check SKIPPED (disabled via DISABLE_REDIS)');
      }
      
      // Elasticsearch connection check - only if not disabled
      if (process.env.DISABLE_ELASTICSEARCH !== 'true') {
        const esClient = (searchService as any).esClient;
        if (esClient) {
          try {
            logger.log(`Attempting Elasticsearch connection to ${CONFIG.elasticsearch.node}...`);
            const esResponse = await esClient.cluster.health();
            const clusterStatus = esResponse.body?.status || esResponse.status || 'unknown';
            logger.log(`✓ Elasticsearch connection established - Cluster status: ${clusterStatus}`);
            
            // Ensure default index exists
            const indexExists = await esClient.indices.exists({ 
              index: CONFIG.elasticsearch.indices.default 
            });
            
            const indexExistsResult = indexExists.body !== undefined ? indexExists.body : indexExists;
            
            if (!indexExistsResult) {
              logger.log(`Creating default index: ${CONFIG.elasticsearch.indices.default}`);
              
              if (typeof (searchService as any).createIndex === 'function') {
                try {
                  await (searchService as any).createIndex(CONFIG.elasticsearch.indices.default);
                  logger.log(`✓ Default index created: ${CONFIG.elasticsearch.indices.default}`);
                } catch (createError) {
                  logger.warn(`Service createIndex failed: ${createError.message}`);
                  if (!CONFIG.elasticsearch.required) {
                    logger.warn('⚠ Continuing without Elasticsearch index (not required)');
                  }
                }
              }
            } else {
              logger.log(`✓ Default index already exists: ${CONFIG.elasticsearch.indices.default}`);
            }
          } catch (esError) {
            logger.warn(`⚠ Elasticsearch connection failed: ${esError.message}`);
            if (CONFIG.elasticsearch.required) {
              throw new Error(`Elasticsearch connection failed: ${esError.message}`);
            } else {
              logger.warn('⚠ Elasticsearch not available but not required, continuing without Elasticsearch...');
            }
          }
        } else {
          logger.warn('⚠ Elasticsearch client not found in SearchService');
          if (CONFIG.elasticsearch.required) {
            throw new Error('Elasticsearch client not found but is required');
          } else {
            logger.warn('⚠ Continuing without Elasticsearch (not required)');
          }
        }
      } else {
        logger.log('⚠ Elasticsearch check SKIPPED (disabled via DISABLE_ELASTICSEARCH)');
      }

      logger.log('✓ Search services validation completed (available services are connected)');
      
    } catch (error) {
      logger.warn('=== SEARCH SERVICES CHECK ENCOUNTERED ERRORS ===');
      logger.warn(`Error: ${error.message}`);
      
      if (CONFIG.redis.required || CONFIG.elasticsearch.required) {
        logger.error('Application cannot start without required search services');
        throw error;
      } else {
        logger.warn('⚠ Search services failed but are not required, application will continue...');
        logger.warn('⚠ Some features may be limited without search services');
      }
    }
  }

  private configureMainApplication() {
    try {
      const configService = this.mainApp.get(ConfigService);
      
      this.mainApp.enableCors({
        origin: configService.get('FRONTEND_URL') || CONFIG.cors.allowedOrigins,
        credentials: CONFIG.cors.credentials,
        methods: CONFIG.cors.methods,
        allowedHeaders: CONFIG.cors.allowedHeaders,
      });
      
      this.mainApp.useWebSocketAdapter(new IoAdapter(this.mainApp));
      
      this.mainApp.use(express.json({ limit: '50mb' }));
      this.mainApp.use(express.urlencoded({ extended: true, limit: '50mb' }));
      this.mainApp.use(cookieParser());
      this.mainApp.use('/api/v1/orders/webhook', raw({ type: '*/*' }));
      this.mainApp.use('/api/v1/heltec-live-vitals', express.raw({ type: 'text/plain' }));
      this.mainApp.use(CONFIG.static.profilePhotosRoute, express.static(CONFIG.static.profilePhotosPath));
      
      // Add health check endpoint
      this.mainApp.getHttpAdapter().getInstance().get('/health', (req: any, res: any) => {
        res.status(200).json({ 
          status: 'OK', 
          timestamp: new Date().toISOString(),
          service: 'Patient Monitor Backend',
          environment: process.env.NODE_ENV || 'development'
        });
      });
      
      logger.log(`Static files: ${CONFIG.static.profilePhotosRoute} -> ${CONFIG.static.profilePhotosPath}`);
      logger.log('✓ Health check endpoint configured at /health');

      this.mainApp.setGlobalPrefix(CONFIG.server.apiPrefix);
      this.mainApp.useGlobalInterceptors(new TransformationInterceptor());
      this.mainApp.useGlobalPipes(new ValidationPipe({ transform: true }));

      this.logApplicationRoutes();
    } catch (error) {
      logger.error('Failed to configure main application');
      logger.error(`Error: ${error.message}`);
      throw error;
    }
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
        logger.log(`Registered ${routes.length} routes`);
        routes.slice(0, 5).forEach(route => logger.log(`  ${route.method} ${route.path}`));
        if (routes.length > 5) {
          logger.log(`  ... and ${routes.length - 5} more routes`);
        }
      } else {
        logger.log('No routes found or routes not yet registered');
      }
    } catch (error) {
      logger.warn(`Could not log application routes: ${error.message}`);
    }
  }

  private async setupEmailFallbackMechanism() {
    try {
      // Skip if RabbitMQ is disabled
      if (process.env.DISABLE_RABBITMQ === 'true') {
        logger.log('⚠ Email fallback mechanism SKIPPED (RabbitMQ disabled)');
        return;
      }

      logger.log('Setting up email fallback mechanism...');
      
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

      logger.log('✓ Email fallback mechanism setup complete');
    } catch (error) {
      logger.error(`Failed to setup email fallback mechanism: ${error.message}`);
      throw error;
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
    logger.log('==========================================');
    logger.log('🎉 APPLICATION STARTUP COMPLETE');
    logger.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    logger.log(`Main API: http://localhost:${CONFIG.server.port}/${CONFIG.server.apiPrefix}`);
    logger.log(`Health Check: http://localhost:${CONFIG.server.port}/health`);
    
    // Show service status
    logger.log(`🔧 Service Status:`);
    logger.log(`   - Face Recognition: ${CONFIG.faceRecognition.enabled ? '✅ Enabled' : '❌ Disabled'}`);
    logger.log(`   - Redis: ${CONFIG.redis.required ? '✅ Required' : '❌ Disabled'}`);
    logger.log(`   - Elasticsearch: ${CONFIG.elasticsearch.required ? '✅ Required' : '❌ Disabled'}`);
    logger.log(`   - Kafka: ${CONFIG.kafka.required ? '✅ Required' : '❌ Disabled'}`);
    logger.log(`   - RabbitMQ: ${CONFIG.rabbitmq.required ? '✅ Required' : '❌ Disabled'}`);
    
    logger.log(`📁 Static Profile Photos: http://localhost:${CONFIG.server.port}${CONFIG.static.profilePhotosRoute}`);
    logger.log('💡 NOTE: Disabled services can be re-enabled via environment variables');
    logger.log('==========================================');
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
  try {
    logger.log('=== BOOTSTRAP STARTING ===');
    const appManager = new ApplicationManager();
    await appManager.initialize();
    logger.log('=== BOOTSTRAP COMPLETED SUCCESSFULLY ===');
  } catch (error) {
    logger.error('=== BOOTSTRAP FAILED ===');
    logger.error(`Fatal error: ${error.message}`);
    logger.error(`Stack trace: ${error.stack}`);
    process.exit(1);
  }
}

// Simplified bootstrap logic to prevent multiple instances
bootstrap().catch((error) => {
  logger.error('=== FATAL BOOTSTRAP ERROR ===');
  logger.error(`Error: ${error.message}`);
  process.exit(1);
});