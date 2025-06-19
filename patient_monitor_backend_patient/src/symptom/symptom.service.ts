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

    return this.mapToDto(symptom);
  }

  async findAll(): Promise<SymptomDto[]> {
    const symptoms = await this.symptomModel.find().exec();
    return symptoms.map(this.mapToDto);
  }

  async searchSymptoms(searchSymptomDto: SearchSymptomDto): Promise<SymptomDto[]> {
    try {
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
            },
          },
        },
      });

      const symptomIds = response.hits.hits.map(hit => hit._id);
      const symptoms = await this.symptomModel.find({
        _id: { $in: symptomIds }
      }).exec();

      return symptoms.map(this.mapToDto);
    } catch (error) {
      this.logger.error(`Search error: ${error.message}`);
      throw error;
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