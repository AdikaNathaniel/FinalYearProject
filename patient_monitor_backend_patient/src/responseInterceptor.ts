import {
  CallHandler,
  ExecutionContext,
  NestInterceptor,
  Injectable,
} from '@nestjs/common';
import { Observable, map } from 'rxjs';

export interface Response<T> {
  message: string | null;
  success: boolean;
  result: T | null;
  error: any | null;
  timestamps: Date;
  statusCode: number;
  path: string;
}

@Injectable()
export class TransformationInterceptor<T>
  implements NestInterceptor<T, Response<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<Response<T>> {
    const response = context.switchToHttp().getResponse();
    const request = context.switchToHttp().getRequest();
    const statusCode = response.statusCode;
    const path = request.url;

    return next.handle().pipe(
      map((data: any) => {
        // Safely extract message and success if present
        const message =
          typeof data === 'object' && data?.message
            ? data.message
            : 'Request successful';

      const success =
  data != null && typeof data === 'object' && 'success' in data
    ? data.success
    : true;


        const result = 
  data != null && typeof data === 'object' && 'result' in data
    ? data.result
    : data;


        return {
          message,
          success,
          result,
          error: null,
          timestamps: new Date(),
          statusCode,
          path,
        };
      }),
    );
  }
}
