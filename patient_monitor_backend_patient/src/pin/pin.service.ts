import { Injectable, BadRequestException, ForbiddenException, Inject, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Pin } from 'src/shared/schema/pin.schema';
import { CreatePinDto } from 'src/users/dto/create-pin.dto';
import { VerifyPinDto } from 'src/users/dto/verify-pin.dto';
import { UpdatePinDto } from 'src/users/dto/update-pin.dto';
import { PIN_LENGTH } from 'src/pin/pin.constants';
import * as bcrypt from 'bcrypt';
import { AntenatalVisitSmsService } from 'src/visit/antenatal-visit-sms.service';
import { SmsNotificationDto } from 'src/users/dto/sms-notification.dto';

@Injectable()
export class PinService {
  private readonly logger = new Logger(PinService.name);
  private readonly MAX_ATTEMPTS = 3;
  private readonly LOCK_TIME = 15 * 60 * 1000; // 15 minutes lock time

  constructor(
    @InjectModel(Pin.name) private pinModel: Model<Pin>,
    @Inject(AntenatalVisitSmsService)
    private readonly smsService: AntenatalVisitSmsService,
  ) {}

  private async sendPinNotification(phone: string, pin: string, action: 'created' | 'updated'): Promise<void> {
    if (!phone) {
      this.logger.error(`Cannot send PIN ${action} notification: Phone number is undefined`);
      return;
    }

    const message = `Your PIN has been ${action}. Please do not share it with anyone.`;
    
    try {
      await this.smsService.sendSms(phone, message);
      this.logger.log(`PIN ${action} SMS sent to ${phone}`);
    } catch (error) {
      this.logger.error(`Failed to send PIN ${action} SMS to ${phone}: ${error.message}`);
      // Don't throw error - SMS failure shouldn't prevent PIN operation
    }
  }

  async createPin(createPinDto: CreatePinDto & { phone: string }): Promise<{ message: string }> {
    const { userId, pin, phone } = createPinDto;

    if (!phone) {
      throw new BadRequestException('Phone number is required');
    }

    // Check if user already has a PIN
    const existingPin = await this.pinModel.findOne({ userId });
    if (existingPin) {
      throw new BadRequestException('PIN already exists for this user');
    }

    // Hash the PIN before storing
    const hashedPin = await bcrypt.hash(pin, 10);

    await this.pinModel.create({
      userId,
      pin: hashedPin,
      phone,
      attempts: 0,
      lastAttempt: null,
      lockedUntil: null,
    });

    // Send SMS notification
    await this.sendPinNotification(phone, pin, 'created');

    return { message: 'PIN created successfully' };
  }

  async verifyPin(verifyPinDto: VerifyPinDto): Promise<{ success: boolean }> {
    const { userId, pin } = verifyPinDto;

    const userPin = await this.pinModel.findOne({ userId });
    if (!userPin) {
      throw new BadRequestException('No PIN found for this user');
    }

    // Check if PIN is locked
    if (userPin.lockedUntil && userPin.lockedUntil > new Date()) {
      throw new ForbiddenException(
        `PIN verification locked until ${userPin.lockedUntil}. Try again later.`,
      );
    }

    // Verify PIN
    const isPinValid = await bcrypt.compare(pin, userPin.pin);
    if (!isPinValid) {
      // Increment attempts
      userPin.attempts += 1;
      userPin.lastAttempt = new Date();

      // Lock if max attempts reached
      if (userPin.attempts >= this.MAX_ATTEMPTS) {
        userPin.lockedUntil = new Date(Date.now() + this.LOCK_TIME);
        await userPin.save();
        throw new ForbiddenException(
          `Too many failed attempts. PIN verification locked for ${this.LOCK_TIME / (60 * 1000)} minutes.`,
        );
      }

      await userPin.save();
      throw new BadRequestException('Invalid PIN');
    }

    // Reset attempts on successful verification
    userPin.attempts = 0;
    userPin.lastAttempt = null;
    userPin.lockedUntil = null;
    await userPin.save();

    return { success: true };
  }

  async updatePin(updatePinDto: UpdatePinDto & { phone: string }): Promise<{ message: string }> {
    const { userId, oldPin, newPin, phone } = updatePinDto;

    if (!phone) {
      throw new BadRequestException('Phone number is required');
    }

    const userPin = await this.pinModel.findOne({ userId });
    if (!userPin) {
      throw new BadRequestException('No PIN found for this user');
    }

    // Verify old PIN first
    const isOldPinValid = await bcrypt.compare(oldPin, userPin.pin);
    if (!isOldPinValid) {
      throw new BadRequestException('Old PIN is incorrect');
    }

    // Hash the new PIN
    const hashedNewPin = await bcrypt.hash(newPin, 10);

    // Update PIN and reset attempts
    userPin.pin = hashedNewPin;
    userPin.phone = phone;
    userPin.attempts = 0;
    userPin.lastAttempt = null;
    userPin.lockedUntil = null;
    await userPin.save();

    // Send SMS notification
    await this.sendPinNotification(phone, newPin, 'updated');

    return { message: 'PIN updated successfully' };
  }

  async deletePin(userId: string): Promise<{ message: string }> {
    // First, find the pin document to get the phone number
    const pinDocument = await this.pinModel.findOne({ userId });
    if (!pinDocument) {
      throw new BadRequestException('No PIN found for this user');
    }
    
    // Get the phone number from the pin document
    const phone = pinDocument.phone;
    
    // Delete the pin document
    const result = await this.pinModel.deleteOne({ userId });
    if (result.deletedCount === 0) {
      throw new BadRequestException('Failed to delete PIN');
    }

    try {
      if (phone) {
        const message = 'Your PIN has been deleted successfully.';
        await this.smsService.sendSms(phone, message);
        this.logger.log(`PIN deletion SMS sent to ${phone}`);
      } else {
        this.logger.warn(`Cannot send PIN deletion SMS: No phone number found in PIN document`);
      }
    } catch (error) {
      this.logger.error(`Failed to send PIN deletion SMS to ${phone}: ${error.message}`);
      // Don't throw error - SMS failure shouldn't prevent PIN deletion
    }

    return { message: 'PIN deleted successfully' };
  }

  async hasPin(userId: string): Promise<boolean> {
    const pin = await this.pinModel.findOne({ userId });
    return !!pin;
  }
}