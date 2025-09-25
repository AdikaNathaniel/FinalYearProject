import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { IContact } from 'src/emergency/interfaces/contact-interface';
import { CreateContactDto } from 'src/users/dto/create-contact.dto';
import { UpdateContactDto } from 'src/users/dto/update-contact.dto';
import { SendSmsDto } from 'src/users/dto/sms-send.dto';
import { HttpService } from '../shared/http/http.service';

@Injectable()
export class EmergencyService {
  constructor(
    @InjectModel('Contact') private readonly contactModel: Model<IContact>,
    private readonly httpService: HttpService,
  ) {}

  async createContact(userId: string, createContactDto: CreateContactDto): Promise<IContact> {
    const newContact = new this.contactModel({
      userId,
      ...createContactDto,
    });
    return newContact.save();
  }

  async getAllContacts(userId: string): Promise<IContact[]> {
    return this.contactModel.find({ userId }).exec();
  }

  async getContactByName(userId: string, name: string): Promise<IContact> {
    const contact = await this.contactModel.findOne({ userId, name }).exec();
    if (!contact) {
      throw new NotFoundException('Contact not found');
    }
    return contact;
  }

  async updateContact(userId: string, name: string, updateContactDto: UpdateContactDto): Promise<IContact> {
    const updatedContact = await this.contactModel.findOneAndUpdate(
      { userId, name },
      updateContactDto,
      { new: true },
    ).exec();
    if (!updatedContact) {
      throw new NotFoundException('Contact not found');
    }
    return updatedContact;
  }

  async deleteContact(userId: string, name: string): Promise<{ message: string }> {
    const result = await this.contactModel.deleteOne({ userId, name }).exec();
    if (result.deletedCount === 0) {
      throw new NotFoundException('Contact not found');
    }
    return { message: 'Contact deleted successfully' };
  }

  async sendEmergencySms(userId: string, sendSmsDto: SendSmsDto): Promise<any> {
    const contacts = await this.getAllContacts(userId);
    const activeContacts = contacts.filter(contact => contact.isActive);

    if (activeContacts.length === 0) {
      throw new NotFoundException('No active emergency contacts found');
    }

    const recipients = activeContacts.map(contact => contact.phoneNumber);
    const message = `EMERGENCY ALERT: ${sendSmsDto.message}`;

    const smsData = {
      sender: this.httpService.senderId, // Using the hardcoded sender ID
      message,
      recipients,
    };

    try {
      const response = await this.httpService.post('/sms/send', smsData);
      return {
        success: true,
        message: 'Emergency SMS sent successfully',
        data: response,
        contacts: activeContacts.map(contact => contact.name),
      };
    } catch (error) {
      throw new Error(`Failed to send SMS: ${error.message}`);
    }
  }
}