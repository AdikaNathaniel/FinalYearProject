import { Injectable, Inject, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Client } from '@elastic/elasticsearch';
import { Symptom } from 'src/shared/schema/symptom.schema';
import { CreateSymptomDto } from 'src/users/dto/create-symptom.dto';
import { SymptomDto } from 'src/users/dto/symptom.dto';
import { ELASTIC_SEARCH_CLIENT } from '../search/constants';
import { SearchSymptomDto } from 'src/users/dto/search-symptom.dto';

@Injectable()
export class SymptomsService {
  private readonly logger = new Logger(SymptomsService.name);
  private readonly INDEX_NAME = 'symptoms';

  constructor(
    @InjectModel(Symptom.name) private readonly symptomModel: Model<Symptom>,
    @Inject(ELASTIC_SEARCH_CLIENT) private readonly esClient: Client,
  ) {}

  async create(createSymptomDto: CreateSymptomDto): Promise<SymptomDto> {
    const createdSymptom = new this.symptomModel(createSymptomDto);
    const symptom = await createdSymptom.save();

    try {
      // Ensure index exists before indexing
      await this.ensureIndexExists();

      // Index in Elasticsearch
      await this.esClient.index({
        index: this.INDEX_NAME,
        id: symptom._id.toString(),
        body: {
          patientId: createSymptomDto.patientId,
          username: createSymptomDto.username,
          symptoms: {
            feelingHeadache: createSymptomDto.feelingHeadache,
            feelingDizziness: createSymptomDto.feelingDizziness,
            vomitingAndNausea: createSymptomDto.vomitingAndNausea,
            painAtTopOfTommy: createSymptomDto.painAtTopOfTommy,
          },
          timestamp: new Date(),
        },
        refresh: true,
      });

      this.logger.log(`Successfully indexed symptom ${symptom._id} in Elasticsearch`);
    } catch (esError) {
      this.logger.error(`Failed to index symptom in Elasticsearch: ${esError.message}`, esError.stack);
      // Don't throw error here - we still want to return the created symptom from MongoDB
    }

    return this.mapToDto(symptom);
  }

  async findAll(): Promise<SymptomDto[]> {
    const symptoms = await this.symptomModel.find().exec();
    return symptoms.map(this.mapToDto);
  }

  async searchSymptoms(searchSymptomDto: SearchSymptomDto): Promise<SymptomDto[]> {
    try {
      this.logger.log(`Starting search for query: "${searchSymptomDto.query}"`);

      // Test Elasticsearch connection
      await this.testElasticsearchConnection();

      // Ensure index exists
      await this.ensureIndexExists();

      // Perform the search
      const response = await this.esClient.search({
        index: this.INDEX_NAME,
        body: {
          query: {
            bool: {
              should: [
                {
                  multi_match: {
                    query: searchSymptomDto.query,
                    fields: ['username', 'patientId'],
                    fuzziness: 'AUTO',
                  },
                },
                {
                  wildcard: {
                    patientId: `*${searchSymptomDto.query}*`,
                  },
                },
                {
                  wildcard: {
                    username: `*${searchSymptomDto.query}*`,
                  },
                },
              ],
              minimum_should_match: 1,
            },
          },
          size: 100, // Limit results
        },
      });

      this.logger.log(`Elasticsearch returned ${response.hits.hits.length} hits`);

      if (response.hits.hits.length === 0) {
        this.logger.log('No results found in Elasticsearch, returning empty array');
        return [];
      }

      const symptomIds = response.hits.hits.map(hit => hit._id);
      this.logger.log(`Searching MongoDB for symptom IDs: ${symptomIds.join(', ')}`);

      const symptoms = await this.symptomModel.find({
        _id: { $in: symptomIds }
      }).exec();

      this.logger.log(`Found ${symptoms.length} symptoms in MongoDB`);

      return symptoms.map(this.mapToDto);
    } catch (error) {
      this.logger.error(`Search error occurred:`, {
        message: error.message,
        stack: error.stack,
        meta: error.meta?.body || error.meta,
        query: searchSymptomDto.query,
      });

      // Fallback to MongoDB search if Elasticsearch fails
      this.logger.warn('Elasticsearch search failed, falling back to MongoDB search');
      return this.fallbackSearch(searchSymptomDto.query);
    }
  }

  /**
   * Test Elasticsearch connection
   */
  private async testElasticsearchConnection(): Promise<void> {
    try {
      const pingResponse = await this.esClient.ping();
      this.logger.log('Elasticsearch connection successful');
    } catch (error) {
      this.logger.error('Elasticsearch ping failed:', error.message);
      throw new Error(`Elasticsearch connection failed: ${error.message}`);
    }
  }

  /**
   * Ensure the symptoms index exists in Elasticsearch
   */
  private async ensureIndexExists(): Promise<void> {
    try {
      const exists = await this.esClient.indices.exists({
        index: this.INDEX_NAME
      });

      if (!exists) {
        this.logger.log(`Creating index: ${this.INDEX_NAME}`);
        
        await this.esClient.indices.create({
          index: this.INDEX_NAME,
          body: {
            mappings: {
              properties: {
                patientId: { 
                  type: 'keyword' 
                },
                username: { 
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword'
                    }
                  }
                },
                symptoms: {
                  properties: {
                    feelingHeadache: { type: 'boolean' },
                    feelingDizziness: { type: 'boolean' },
                    vomitingAndNausea: { type: 'boolean' },
                    painAtTopOfTommy: { type: 'boolean' }
                  }
                },
                timestamp: { 
                  type: 'date' 
                }
              }
            },
            settings: {
              number_of_shards: 1,
              number_of_replicas: 0
            }
          }
        });
        
        this.logger.log(`Successfully created index: ${this.INDEX_NAME}`);
      } else {
        this.logger.log(`Index ${this.INDEX_NAME} already exists`);
      }
    } catch (error) {
      this.logger.error(`Error managing index ${this.INDEX_NAME}:`, error.message);
      throw new Error(`Failed to ensure index exists: ${error.message}`);
    }
  }

  /**
   * Fallback search using MongoDB when Elasticsearch fails
   */
  private async fallbackSearch(query: string): Promise<SymptomDto[]> {
    try {
      this.logger.log(`Performing fallback MongoDB search for: "${query}"`);
      
      const symptoms = await this.symptomModel.find({
        $or: [
          { username: { $regex: query, $options: 'i' } },
          { patientId: { $regex: query, $options: 'i' } }
        ]
      }).limit(100).exec();

      this.logger.log(`Fallback search found ${symptoms.length} results`);
      return symptoms.map(this.mapToDto);
    } catch (error) {
      this.logger.error('Fallback search also failed:', error.message);
      throw new Error(`Both Elasticsearch and MongoDB searches failed: ${error.message}`);
    }
  }

  /**
   * Get search statistics for debugging
   */
  async getSearchStats(): Promise<any> {
    try {
      const [esStats, mongoCount] = await Promise.all([
        this.esClient.count({ index: this.INDEX_NAME }).catch(() => ({ count: 0 })),
        this.symptomModel.countDocuments().exec()
      ]);

      return {
        elasticsearch: {
          connected: await this.esClient.ping().then(() => true).catch(() => false),
          indexExists: await this.esClient.indices.exists({ index: this.INDEX_NAME }).catch(() => false),
          documentCount: esStats.count || 0
        },
        mongodb: {
          documentCount: mongoCount
        }
      };
    } catch (error) {
      this.logger.error('Failed to get search stats:', error.message);
      return {
        error: error.message
      };
    }
  }

  private mapToDto(symptom: any): SymptomDto {
    return {
      id: symptom._id,
      patientId: symptom.patientId,
      username: symptom.username,
      feelingHeadache: symptom.feelingHeadache,
      feelingDizziness: symptom.feelingDizziness,
      vomitingAndNausea: symptom.vomitingAndNausea,
      painAtTopOfTommy: symptom.painAtTopOfTommy,
      createdAt: symptom.createdAt,
      updatedAt: symptom.updatedAt,
    };
  }
}