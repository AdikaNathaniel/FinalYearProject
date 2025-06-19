import { Injectable, Inject, Logger } from '@nestjs/common';
import { Client } from '@elastic/elasticsearch';
import * as Redis from 'ioredis';
import {
  SearchResponse,
  IndexDocumentPayload,
  DeleteDocumentPayload,
  SearchParams,
} from './search.interface';
import { ELASTIC_SEARCH_CLIENT, REDIS_CLIENT } from './constants';
import { SearchResponseDto } from 'src/users/dto/search-result.dto';

@Injectable()
export class SearchService {
  private readonly logger = new Logger(SearchService.name);
  private readonly CACHE_TTL = 3600; // 1 hour in seconds

  constructor(
    @Inject(ELASTIC_SEARCH_CLIENT) private readonly esClient: Client,
    @Inject(REDIS_CLIENT) private readonly redisClient: Redis.Redis,
  ) {}

  async indexDocument(payload: IndexDocumentPayload): Promise<boolean> {
    try {
      await this.esClient.index({
        index: payload.index,
        id: payload.id,
        body: payload.body,
        refresh: true,
      });
      return true;
    } catch (error) {
      this.logger.error(`Error indexing document: ${error.message}`);
      return false;
    }
  }

  async deleteDocument(payload: DeleteDocumentPayload): Promise<boolean> {
    try {
      await this.esClient.delete({
        index: payload.index,
        id: payload.id,
      });
      return true;
    } catch (error) {
      this.logger.error(`Error deleting document: ${error.message}`);
      return false;
    }
  }

  async search(params: SearchParams): Promise<SearchResponseDto> {
    const cacheKey = this.getCacheKey(params);
    
    // Try to get from cache first
    const cachedResult = await this.redisClient.get(cacheKey);
    if (cachedResult) {
      return JSON.parse(cachedResult);
    }

    const { index, query, fields = [], limit = 10, offset = 0 } = params;

    try {
      const esResponse = await this.esClient.search({
        index,
        body: {
          query: {
            multi_match: {
              query,
              fields: fields.length ? fields : ['*'],
              fuzziness: 'AUTO',
            },
          },
          from: offset,
          size: limit,
        },
      });

      const results = esResponse.hits.hits.map((hit) => ({
        id: hit._id,
        index: hit._index,
        score: hit._score,
        source: hit._source,
      }));

      const totalHits = typeof esResponse.hits.total === 'number'
        ? esResponse.hits.total
        : esResponse.hits.total.value;

      const response: SearchResponseDto = {
        results,
        total: totalHits,
        took: esResponse.took,
      };

      // Cache the result
      await this.redisClient.set(cacheKey, JSON.stringify(response), 'EX', this.CACHE_TTL);

      return response;
    } catch (error) {
      this.logger.error(`Error searching documents: ${error.message}`);
      throw error;
    }
  }

  private getCacheKey(params: SearchParams): string {
    return `search:${params.index}:${params.query}:${params.fields?.join(',') || '*'}:${params.limit}:${params.offset}`;
  }

  async clearIndex(index: string): Promise<boolean> {
    try {
      await this.esClient.indices.delete({ index });
      return true;
    } catch (error) {
      this.logger.error(`Error clearing index: ${error.message}`);
      return false;
    }
  }

  async createIndex(index: string): Promise<boolean> {
    try {
      await this.esClient.indices.create({ index });
      return true;
    } catch (error) {
      this.logger.error(`Error creating index: ${error.message}`);
      return false;
    }
  }
}