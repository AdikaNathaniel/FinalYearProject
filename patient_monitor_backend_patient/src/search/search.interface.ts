export interface SearchResult<T = any> {
  id: string;
  index: string;
  score: number;
  source: T;
}

export interface SearchResponse<T = any> {
  results: SearchResult<T>[];
  total: number;
  took: number;
}

export interface IndexDocumentPayload {
  index: string;
  id: string;
  body: any;
}

export interface DeleteDocumentPayload {
  index: string;
  id: string;
}

export interface SearchParams {
  index: string;
  query: string;
  fields?: string[];
  limit?: number;
  offset?: number;
}