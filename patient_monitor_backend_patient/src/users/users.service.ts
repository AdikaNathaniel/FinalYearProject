import { Inject, Injectable } from '@nestjs/common';
import { userTypes } from 'src/shared/schema/users';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import config from 'config';
import { UserRepository } from 'src/shared/repositories/user.repository';
import { comparePassword, generateHashPassword } from 'src/shared/utility/password-manager';
import { EmailService } from 'src/email/email.service';
import { generateAuthToken } from 'src/shared/utility/token-generator';
import { HttpService } from '@nestjs/axios';
import { HttpException } from '@nestjs/common';
import { HttpStatus } from '@nestjs/common';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class UsersService {
  private readonly MAX_FAILED_ATTEMPTS = 3;
  // private readonly ACCOUNT_LOCK_DURATION = 30 * 60 * 1000; // 30 minutes in milliseconds
  private readonly ACCOUNT_LOCK_DURATION = null;

  constructor(
    @Inject(UserRepository) private readonly userDB: UserRepository,
    private readonly httpService: HttpService,
    private readonly emailService: EmailService,
  ) {}

  async create(createUserDto: CreateUserDto) {
    try {
      createUserDto.password = await generateHashPassword(createUserDto.password);

      const user = await this.userDB.findOne({ name: createUserDto.name });
      if (user) {
        throw new Error('User already exists');
      }

      const otp = await this.generateAndSendOtp(createUserDto.email);
      const newUser = await this.userDB.create({ 
        ...createUserDto, 
        otp,
        failedLoginAttempts: 0,
        isActive: true
      });

      if (newUser.type !== userTypes.ADMIN) {
        await this.emailService.sendOTPEmail(newUser.email, otp);
      }

      return {
        success: true,
        message: newUser.type === userTypes.ADMIN
          ? 'Admin created successfully'
          : 'Please activate your account by verifying your email. We have sent you a mail with the OTP.',
        result: { email: newUser.email },
      };
    } catch (error) {
      throw error;
    }
  }




  async sendAccountDeactivatedEmail(email: string): Promise<{ success: boolean; message: string }> {
    // Implement your email sending logic here, e.g., using nodemailer or any email provider
    // For now, let's mock the response
    console.log(`Sending account deactivated email to ${email}`);
    // TODO: Replace with actual email sending logic
    return { success: true, message: 'Account deactivated email sent' };
  }
  async login(email: string, password: string) {
    try {
      const userExists = await this.userDB.findOne({ email });
      if (!userExists) {
        throw new Error('Invalid email or password');
      }

      if (userExists.lockUntil && userExists.lockUntil > new Date()) {
        const remainingTime = Math.ceil((userExists.lockUntil.getTime() - Date.now()) / (60 * 1000));
        throw new Error(`Account is temporarily locked. Try again after ${remainingTime} minutes.`);
      }

      if (!userExists.isVerified) {
        throw new Error('Please verify your email');
      }

      if (!userExists.isActive) {
        throw new Error('Your account is deactivated. Please contact support.');
      }

      const isPasswordMatch = await comparePassword(password, userExists.password);
      
      if (!isPasswordMatch) {
        const updatedFailedAttempts = userExists.failedLoginAttempts + 1;
        let lockUntil = null;
        
        if (updatedFailedAttempts >= this.MAX_FAILED_ATTEMPTS) {
          lockUntil = new Date(Date.now() + this.ACCOUNT_LOCK_DURATION);
          await this.userDB.updateOne(
            { _id: userExists._id },
            { 
              failedLoginAttempts: updatedFailedAttempts,
              lockUntil,
              isActive: false
            }
          );
          
          // await this.emailService.sendAccountDeactivatedEmail(userExists.email);
          throw new Error('Your account has been deactivated due to multiple failed attempts. Please contact support.');
        } else {
          await this.userDB.updateOne(
            { _id: userExists._id },
            { 
              failedLoginAttempts: updatedFailedAttempts,
              lockUntil: updatedFailedAttempts === this.MAX_FAILED_ATTEMPTS - 1 ? 
                new Date(Date.now() + this.ACCOUNT_LOCK_DURATION) : null
            }
          );
          throw new Error(`Invalid email or password. ${this.MAX_FAILED_ATTEMPTS - updatedFailedAttempts} attempts remaining.`);
        }
      }

      if (userExists.failedLoginAttempts > 0 || userExists.lockUntil) {
        await this.userDB.updateOne(
          { _id: userExists._id },
          { 
            failedLoginAttempts: 0,
            lockUntil: null
          }
        );
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
      const user = await this.userDB.findOne({ email });
      if (!user) {
        throw new Error('User not found');
      }
      if (user.otp !== otp) {
        throw new Error('Invalid OTP');
      }

      await this.userDB.updateOne(
        { email }, 
        { 
          isVerified: true, 
          otp: null, 
          otpExpiryTime: null,
          isActive: true,
          failedLoginAttempts: 0,
          lockUntil: null
        }
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
      const user = await this.userDB.findOne({ email });
      if (!user) {
        throw new Error('User not found');
      }
      if (user.isVerified) {
        throw new Error('Email already verified');
      }

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
      const user = await this.userDB.findOne({ email });
      if (!user) {
        throw new Error('User not found');
      }

      if (!user.isActive) {
        throw new Error('Your account is deactivated. Please contact support.');
      }

      const tempPassword = Math.random().toString(36).substring(2, 12);
      const hashedPassword = await generateHashPassword(tempPassword);
      await this.userDB.updateOne(
        { _id: user._id }, 
        { 
          password: hashedPassword,
          failedLoginAttempts: 0,
          lockUntil: null
        }
      );

      const emailResponse = await this.emailService.sendForgotPasswordEmail(user.email, tempPassword);

      if (!emailResponse.success) {
        throw new Error(emailResponse.message);
      }

      return {
        success: true,
        message: 'New password sent to your email',
        result: { email: user.email },
      };
    } catch (error) {
      throw error;
    }
  }

  async findAll(type?: string) {
    try {
      const query = type ? { type } : {};
      const users = await this.userDB.find(query);
  
      const userList = users.map((user) => ({
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        type: user.type,
        card: user.card,
        isVerified: user.isVerified,
        isActive: user.isActive,
        failedLoginAttempts: user.failedLoginAttempts
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

  async getUserDetails(userId: string) {
    try {
      const user = await this.userDB.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      return {
        success: true,
        message: 'User details fetched successfully',
        result: {
          id: user._id.toString(),
          name: user.name,
          email: user.email,
          type: user.type,
          card: user.card,
          isVerified: user.isVerified,
          isActive: user.isActive
        },
      };
    } catch (error) {
      throw error;
    }
  }

  async updatePasswordOrName(updatePasswordOrNameDto: UpdateUserDto) {
    try {
      const { email, oldPassword, newPassword, name } = updatePasswordOrNameDto;
      if (!name && !newPassword) {
        throw new Error('Please provide name or password');
      }
      const user = await this.userDB.findOne({ email });
      if (!user) {
        throw new Error('User not found');
      }

      if (!user.isActive) {
        throw new Error('Your account is deactivated. Please contact support.');
      }

      if (newPassword) {
        const isPasswordMatch = await comparePassword(oldPassword, user.password);
        if (!isPasswordMatch) {
          throw new Error('Invalid current password');
        }
        const password = await generateHashPassword(newPassword);
        await this.userDB.updateOne(
          { _id: user._id }, 
          { 
            password,
            failedLoginAttempts: 0,
            lockUntil: null
          }
        );
      }
      if (name) {
        await this.userDB.updateOne({ _id: user._id }, { name });
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

  // async reactivateAccount(email: string, currentUserId: string) {
  //   try {
  //     const currentUser = await this.userDB.findById(currentUserId);
  //     if (!currentUser || currentUser.type !== userTypes.ADMIN) {
  //       throw new Error('Only admin can reactivate accounts');
  //     }

  //     const user = await this.userDB.findOne({ email });
  //     if (!user) {
  //       throw new Error('User not found');
  //     }

  //     if (user.isActive) {
  //       throw new Error('Account is already active');
  //     }

  //     await this.userDB.updateOne(
  //       { email },
  //       {
  //         isActive: true,
  //         failedLoginAttempts: 0,
  //         lockUntil: null
  //       }
  //     );

  //     await this.emailService.sendAccountReactivatedEmail(user.email);

  //     return {
  //       success: true,
  //       message: 'Account reactivated successfully',
  //       result: {
  //         email: user.email,
  //         name: user.name,
  //         reactivatedBy: currentUser.email
  //       }
  //     };
  //   } catch (error) {
  //     throw error;
  //   }
  // }



async reactivateAccount(email: string, adminEmail: string) {
  try {
    // Verify admin status by checking the email in database
    const adminUser = await this.userDB.findOne({ email: adminEmail, type: userTypes.ADMIN });
    if (!adminUser) {
      throw new Error('Only admin can reactivate accounts');
    }

    const user = await this.userDB.findOne({ email });
    if (!user) {
      throw new Error('User not found');
    }

    // Check if account needs reactivation (either inactive OR locked)
    const isLocked = user.lockUntil && user.lockUntil > new Date();
    const isInactive = !user.isActive;
    const hasFailedAttempts = user.failedLoginAttempts > 0;

    if (!isLocked && !isInactive && !hasFailedAttempts) {
      throw new Error('Account is already active and unlocked');
    }

    // Reactivate the account and clear all lock-related fields
    await this.userDB.updateOne(
      { email },
      {
        isActive: true,
        failedLoginAttempts: 0,
        lockUntil: null
      }
    );

    // await this.emailService.sendAccountReactivatedEmail(user.email);

    return {
      success: true,
      message: 'Account reactivated and unlocked successfully',
      result: {
        email: user.email,
        name: user.name,
        reactivatedBy: adminEmail
      }
    };
  } catch (error) {
    throw error;
  }
}

  remove(id: number) {
    return `This action removes a #${id} user`;
  }

  private async generateAndSendOtp(email: string) {
    console.log(`Generating OTP for ${email}`);
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    console.log(`Generated OTP: ${otp}`);
    const otpExpiryTime = new Date(Date.now() + 10 * 60 * 1000);

    await this.userDB.updateOne(
      { email },
      {
        otp,
        otpExpiryTime,
      },
    );

    try {
      console.log(`Attempting to send OTP email to ${email}`);
      const emailResult = await this.emailService.sendOTPEmail(email, otp);
      console.log(`Email service result:`, emailResult);
      
      if (!emailResult.success) {
        throw new Error(emailResult.message);
      }
      
      return otp;
    } catch (error) {
      console.error(`Failed to send OTP email: ${error.message}`);
      throw new HttpException(
        `Failed to send OTP: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}