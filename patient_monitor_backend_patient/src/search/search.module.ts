import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SearchService } from './search.service';
import { elasticSearchProvider, redisProvider } from './search.provider';
import { SearchController } from './search.controller';
import { SearchQuery, SearchQuerySchema } from 'src/shared/schema/search-query.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SearchQuery.name, schema: SearchQuerySchema },
    ]),
  ],
  providers: [elasticSearchProvider, redisProvider, SearchService],
  controllers: [SearchController],
  exports: [SearchService],
})
export class SearchModule {}