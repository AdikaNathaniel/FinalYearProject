import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  HttpCode,
  HttpStatus,
  Res,
  Put,
  Query,
  HttpException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { Response } from 'express';
// import { Roles } from 'src/shared/middleware/role.decorators';
import { userTypes } from 'src/shared/schema/users';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  async create(@Body() createUserDto: CreateUserDto) {
    try {
      return await this.usersService.create(createUserDto);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('/login')
  @HttpCode(HttpStatus.OK)
  async login(
    @Body() loginUser: { email: string; password: string },
    @Res({ passthrough: true }) response: Response,
  ) {
    try {
      const loginRes = await this.usersService.login(
        loginUser.email,
        loginUser.password,
      );
      
      if (loginRes.success) {
        response.cookie('_digi_auth_token', loginRes.result?.token, {
          httpOnly: true,
        });
        delete loginRes.result?.token;
      }
      
      return loginRes;
    } catch (error) {
      // Handle specific error cases
      if (error.message.includes('deactivated')) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.FORBIDDEN, // 403 for account deactivated
        );
      } else if (error.message.includes('locked')) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.TOO_MANY_REQUESTS, // 429 for account locked
        );
      } else if (error.message.includes('verify your email')) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.FORBIDDEN, // 403 for unverified email
        );
      } else if (error.message.includes('Invalid email or password') || error.message.includes('attempts remaining')) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.UNAUTHORIZED, // 401 for wrong credentials
        );
      } else {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.BAD_REQUEST,
        );
      }
    }
  }

  @Get('/verify-email/:otp/:email')
  async verifyEmail(@Param('otp') otp: string, @Param('email') email: string) {
    try {
      return await this.usersService.verifyEmail(otp, email);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get('send-otp-email/:email')
  async sendOtpEmail(@Param('email') email: string) {
    try {
      return await this.usersService.sendOtpEmail(email);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Put('/logout')
  async logout(@Res() res: Response) {
    res.clearCookie('_digi_auth_token');
    return res.status(HttpStatus.OK).json({
      success: true,
      message: 'Logout successfully',
    });
  }

  @Get('forgot-password/:email')
  async forgotPassword(@Param('email') email: string) {
    try {
      return await this.usersService.forgotPassword(email);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get()
  async findAll(@Query('type') type: string) {
    try {
      return await this.usersService.findAll(type);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Patch('/update-password-or-name')
  async update(@Body() updateUserDto: UpdateUserDto) {
    try {
      return await this.usersService.updatePasswordOrName(updateUserDto);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Put('/reactivate-account/:email')
  // @Roles(userTypes.ADMIN)
  async reactivateAccount(
    @Param('email') email: string,
    @Body() body: { adminEmail: string }
  ) {
    try {
      return await this.usersService.reactivateAccount(email, body.adminEmail);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.usersService.remove(+id);
  }
}