import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { userTypes } from '../schema/users';
import { ROLES_KEY } from './role.decorators';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<userTypes[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    // Allow access if no roles are required
    if (!requiredRoles || requiredRoles.length === 0) {
      return true; 
    }

    const { user } = await context.switchToHttp().getRequest();
    if (!user || !user.type) {
      return false; // Deny access if user is not present
    }

    return requiredRoles.some(role => user.type.includes(role));
  }
}