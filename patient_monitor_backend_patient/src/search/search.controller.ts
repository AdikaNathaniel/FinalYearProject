import { Controller, Post, Body, Get, Query } from '@nestjs/common';
import { SearchService } from './search.service';
import { SearchRequestDto } from 'src/users/dto/search-request.dto';
import { SearchResponseDto } from 'src/users/dto/search-result.dto';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  // GET method with query parameters
  @Get()
  async searchWithQuery(@Query() params: SearchRequestDto): Promise<SearchResponseDto> {
    return this.searchService.search(params);
  }

  // POST method with JSON body (recommended for complex searches)
  @Post()
  async searchWithBody(@Body() params: SearchRequestDto): Promise<SearchResponseDto> {
    return this.searchService.search(params);
  }

  @Post('index')
  async indexDocument(@Body() payload: any) {
    return this.searchService.indexDocument(payload);
  }

  @Post('delete')
  async deleteDocument(@Body() payload: any) {
    return this.searchService.deleteDocument(payload);
  }
}