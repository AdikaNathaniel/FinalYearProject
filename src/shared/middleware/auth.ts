import {
  Inject,
  Injectable,
  NestMiddleware,
  UnauthorizedException,
} from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';
import { UserRepository } from '../repositories/user.repository';
import { decodeAuthToken } from '../utility/token-generator';

@Injectable()
export class AuthMiddleware implements NestMiddleware {
  constructor(
    @Inject(UserRepository) private readonly userDB: UserRepository,
  ) {}

  async use(req: Request | any, res: Response, next: NextFunction) {
    try {
      console.log('AuthMiddleware - Request Headers:', req.headers);

      // Allow access to specific public routes
      if (this.isPublicRoute(req.path, req.method) || this.isCsrfSkippedRoute(req.originalUrl)) {
        console.log('Public route or CSRF skipped, proceeding to next middleware.');
        return next();
      }

      const token = req.cookies._digi_auth_token;
      let user;

      if (token) {
        const decodedData: any = decodeAuthToken(token);
        user = await this.userDB.findById(decodedData.id);

        if (!user) {
          console.log('No user found for the given token, unauthorized access.');
          throw new UnauthorizedException('Unauthorized');
        }

        console.log('Authenticated User:', user);
        req.user = user;
      } else {
        console.log('No token found in cookies, checking role from headers...');

        // Accept role from request headers
        const roleFromHeader = req.headers['role'];
        const emailFromHeader = req.headers['email'];

        if (roleFromHeader && (roleFromHeader === 'Seller' || roleFromHeader === 'Admin')) {
          user = { 
            role: roleFromHeader,
            email: emailFromHeader
          };
          req.user = user;
          console.log('User role from header:', user.role);
        } else {
          throw new UnauthorizedException('Missing auth token');
        }
      }

      // TEMPORARY: BYPASS ROLE CHECK
      next();

    } catch (error) {
      console.error('Authentication Error:', error);
      throw new UnauthorizedException(error.message);
    }
  }

  private isPublicRoute(path: string, method: string): boolean {
    const publicRoutes = [
      { path: '/api/v1', method: 'GET' },
      { path: '/api/v1/test', method: 'GET' },
      { path: '/api/v1/csrf-token', method: 'GET' },
      { path: '/api/v1/users', method: 'POST' },
      { path: '/api/v1/users', method: 'GET' },
      { path: '/api/v1/users/login', method: 'POST' },
      { path: '/api/v1/users/verify-email', method: 'GET' },
      { path: '/api/v1/users/send-otp-email', method: 'GET' },
      { path: '/api/v1/users/logout', method: 'PUT' },
      { path: '/api/v1/users/forgot-password', method: 'GET' },
      { path: '/api/v1/users/update-name-password', method: 'PATCH' },
      { path: '/api/v1/users', method: 'DELETE' },
      { path: '/api/v1/products', method: 'GET' },
      { path: '/api/v1/products/', method: 'GET' },
      { path: '/api/v1/products/', method: 'PATCH' },
      { path: '/api/v1/products/', method: 'DELETE' },
      { path: '/api/v1/orders/webhook', method: 'POST' }
    ];

    return publicRoutes.some(route => {
      const pathMatch = path.startsWith(route.path);
      return pathMatch && method === route.method;
    });
  }

  private isCsrfSkippedRoute(url: string): boolean {
    const isSkipped = url.includes('/orders/webhook');
    if (isSkipped) {
      console.log('CSRF check skipped for URL:', url);
    }
    return isSkipped;
  }
}