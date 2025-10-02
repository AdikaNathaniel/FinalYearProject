import { Inject, Injectable } from '@nestjs/common';
import { userTypes } from 'src/shared/schema/users';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import config from 'config';
import { UserRepository } from 'src/shared/repositories/user.repository';
import {
  comparePassword,
  generateHashPassword,
} from 'src/shared/utility/password-manager';
import { sendEmail } from 'src/shared/utility/mail-handler';
import { generateAuthToken } from 'src/shared/utility/token-generator';
import { HttpService } from '@nestjs/axios';
import { HttpException } from '@nestjs/common';
import { HttpStatus } from '@nestjs/common';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class UsersService {
  constructor(
    @Inject(UserRepository) private readonly userDB: UserRepository,
    private readonly httpService: HttpService,
  ) {}

  async create(createUserDto: CreateUserDto) {
    try {
      // Generate the hash password
      createUserDto.password = await generateHashPassword(
        createUserDto.password,
      );

      // Check if it is for admin
      // if (
      //   createUserDto.type === userTypes.ADMIN &&
      //   createUserDto.secretToken !== config.get('adminSecretToken')
      // ) {
      //   throw new Error('Not allowed to create admin');
      // } else if (createUserDto.type !== userTypes.PREGNANT) {
      //   createUserDto.isVerified = true;
      // }

      // User already exists
      const user = await this.userDB.findOne({
        name: createUserDto.name,
      });
      if (user) {
        throw new Error('User already exists');
      }

      // Generate and send OTP
      const otp = await this.generateAndSendOtp(createUserDto.email);

      const newUser = await this.userDB.create({
        ...createUserDto,
        otp,
      });

      if (newUser.type !== userTypes.ADMIN) {
        sendEmail(
          newUser.email,
          config.get('emailService.emailTemplates.verifyEmail'),
          'Email verification - Digizone',
          {
            customerName: newUser.name,
            customerEmail: newUser.email,
            customerType: newUser.type,
            customerCard: newUser.card,
            otp,
          },
        );
      }

      return {
        success: true,
        message:
          newUser.type === userTypes.ADMIN
            ? 'Admin created successfully'
            : 'Please activate your account by verifying your email. We have sent you a mail with the OTP.',
        result: { email: newUser.email },
      };
    } catch (error) {
      throw error;
    }
  }

  async login(email: string, password: string) {
    try {
      const userExists = await this.userDB.findOne({
        email,
      });
      if (!userExists) {
        throw new Error('Invalid email or password');
      }
      if (!userExists.isVerified) {
        throw new Error('Please verify your email');
      }
      const isPasswordMatch = await comparePassword(
        password,
        userExists.password,
      );
      if (!isPasswordMatch) {
        throw new Error('Invalid email or password');
      }
      const token = await generateAuthToken(userExists._id.toString());

      return {
        success: true,
        message: 'Login successful',
        result: {
          user: {
            name: userExists.name,
            email: userExists.email,
            type: userExists.type,
            card: userExists.card,
            id: userExists._id.toString(),
          },
          token,
        },
      };
    } catch (error) {
      throw error;
    }
  }

  async verifyEmail(otp: string, email: string) {
    try {
      const user = await this.userDB.findOne({
        email,
      });
      if (!user) {
        throw new Error('User not found');
      }
      if (user.otp !== otp) {
        throw new Error('Invalid OTP');
      }

      const currentTime = new Date();
      const otpTime = new Date(user.otpExpiryTime);
      const timeDifferenceInMinutes = (otpTime.getTime() - currentTime.getTime()) / (1000 * 60);
      // Check if OTP is still valid (has not exceeded 10 minutes)
      // if (timeDifferenceInMinutes < 0) {
      //   // Generate a new OTP instead of throwing an error
      //   const newOtp = await this.generateAndSendOtp(email);
      //   throw new Error('OTP has expired. A new OTP has been sent to your email.');
      // }
  
      await this.userDB.updateOne(
        {
          email,
        },
        {
          isVerified: true,
          otp: null,
          otpExpiryTime: null
        },
      );
      return {
        success: true,
        message: 'Email verified successfully. You can log in now.',
      };
    } catch (error) {
      throw error;
    }
  }

  async sendOtpEmail(email: string) {
    try {
      const user = await this.userDB.findOne({
        email,
      });
      if (!user) {
        throw new Error('User not found');
      }
      if (user.isVerified) {
        throw new Error('Email already verified');
      }

      // Generate and send OTP
      const otp = await this.generateAndSendOtp(email);

      return {
        success: true,
        message: 'OTP sent successfully',
        result: { email },
      };
    } catch (error) {
      throw error;
    }
  }

  async forgotPassword(email: string) {
    try {
      const user = await this.userDB.findOne({
        email,
      });
      if (!user) {
        throw new Error('User not found');
      }
      let password = Math.random().toString(36).substring(2, 12);
      const tempPassword = password;
      password = await generateHashPassword(password);
      await this.userDB.updateOne(
        {
          _id: user._id,
        },
        {
          password,
        },
      );

      sendEmail(
        user.email,
        config.get('emailService.emailTemplates.forgotPassword'),
        'Forgot password - Digizone',
        {
          customerName: user.name,
          customerEmail: user.email,
          customerCard: user.card,
          newPassword: password,
          loginLink: config.get('loginLink'),
        },
      );

      return {
        success: true,
        message: 'Password sent to your email',
        result: { email: user.email, password: tempPassword },
      };
    } catch (error) {
      throw error;
    }
  }

  async findAll(type: string) {
    try {
      const users = await this.userDB.find({ type });

      // Structure response to include user details
      const userList = users.map((user) => ({
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        type: user.type,
        card: user.card,
        isVerified: user.isVerified,
      }));

      return {
        success: true,
        message: 'Users fetched successfully',
        result: userList,
      };
    } catch (error) {
      throw error;
    }
  }

  async updatePasswordOrName(
    id: string,
    updatePasswordOrNameDto: UpdateUserDto,
  ) {
    try {
      const { oldPassword, newPassword, name } = updatePasswordOrNameDto;
      if (!name && !newPassword) {
        throw new Error('Please provide name or password');
      }
      const user = await this.userDB.findOne({
        _id: id,
      });
      if (!user) {
        throw new Error('User not found');
      }
      if (newPassword) {
        const isPasswordMatch = await comparePassword(
          oldPassword,
          user.password,
        );
        if (!isPasswordMatch) {
          throw new Error('Invalid current password');
        }
        const password = await generateHashPassword(newPassword);
        await this.userDB.updateOne(
          {
            _id: id,
          },
          {
            password,
          },
        );
      }
      if (name) {
        await this.userDB.updateOne(
          {
            _id: id,
          },
          {
            name,
          },
        );
      }
      return {
        success: true,
        message: 'User updated successfully',
        result: {
          name: user.name,
          email: user.email,
          type: user.type,
          id: user._id.toString(),
        },
      };
    } catch (error) {
      throw error;
    }
  }

  remove(id: number) {
    return `This action removes a #${id} user`;
  }

  private async generateAndSendOtp(email: string) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    // Increased expiry time to 10 minutes
    const otpExpiryTime = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  
    await this.userDB.updateOne(
      { email },
      {
        otp,
        otpExpiryTime,
      },
    );
  
    // Send OTP via notification service
    try {
      const response = await firstValueFrom(
        this.httpService.post('http://localhost:3001/notifications/send-otp', {
          email,
          otp,
        }),
      );
      return otp;
    } catch (error) {
      throw new HttpException(
        'Failed to send OTP',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
