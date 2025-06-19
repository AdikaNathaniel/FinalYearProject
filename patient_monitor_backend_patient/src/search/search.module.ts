import { Module } from '@nestjs/common';
import { SearchService } from './search.service';
import { elasticSearchProvider, redisProvider } from './search.provider';
import { SearchController } from './search.controller';

@Module({
  providers: [elasticSearchProvider, redisProvider, SearchService],
  controllers: [SearchController],
  exports: [SearchService],
})
export class SearchModule {}