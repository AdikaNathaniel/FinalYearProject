export class SearchResultDto<T = any> {
  id: string;
  index: string;
  score: number;
  source: T;
}

export class SearchResponseDto<T = any> {
  results: SearchResultDto<T>[];
  total: number;
  took: number;
}