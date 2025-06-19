import { Provider } from '@nestjs/common';
import { Client } from '@elastic/elasticsearch';
import Redis from 'ioredis';
import { ELASTIC_SEARCH_CLIENT, REDIS_CLIENT } from './constants';

export const elasticSearchProvider: Provider = {
  provide: ELASTIC_SEARCH_CLIENT,
  useFactory: () => {
    return new Client({
      node: process.env.ELASTICSEARCH_HOST || 'http://localhost:9200',
    });
  },
};

export const redisProvider: Provider = {
  provide: REDIS_CLIENT,
  useFactory: () => {
    return new Redis({
      host: process.env.REDIS_HOST || 'localhost',
      port: 6379,
    });
  },
};