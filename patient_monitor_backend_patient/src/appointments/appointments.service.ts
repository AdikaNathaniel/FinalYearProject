import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { CreateAppointmentDto } from 'src/users/dto/create-appointment.dto'; // Adjusted import path
import { Model } from 'mongoose';
import { UpdateAppointmentDto } from 'src/users/dto/update-appointment.dto'; // Adjusted import path
import { Appointment } from 'src/shared/schema/appointment.schema';

@Injectable()
export class AppointmentsService {
  constructor(@InjectModel(Appointment.name) private appointmentModel: Model<Appointment>) {}

  async create(createAppointmentDto: CreateAppointmentDto): Promise<Appointment> {
    const createdAppointment = new this.appointmentModel({
      ...createAppointmentDto,
      details: {
        patient_name: createAppointmentDto.patient_name,
        condition: createAppointmentDto.condition,
        notes: createAppointmentDto.notes,
      },
    });
    return createdAppointment.save();
  }

  async findAll(): Promise<any> {
    try {
      // Fetch all appointments from the database
      const appointments = await this.appointmentModel.find().exec();

      // Structure the response to include appointment details
      const appointmentList = appointments.map((appointment) => ({
        email: appointment.email,
        day: appointment.day,
        time: appointment.time,
        details: appointment.details, // Include the details field
      }));
      return {
        success: true,
        message: 'Appointments fetched successfully',
        result: appointmentList,
      };
    } catch (error) {
      throw error; // You may want to handle the error more gracefully
    }
  }

  async removeLastAppointment(): Promise<{ success: boolean; message: string }> {
    try {
      // Find the most recent appointment
      const lastAppointment = await this.appointmentModel.findOne().sort({ createdAt: -1 }).exec();
      if (!lastAppointment) {
        return { success: false, message: 'No appointments found to delete' }; // Return a message instead of throwing an error
      }
      // Delete the found appointment
      await this.appointmentModel.deleteOne({ _id: lastAppointment._id }).exec();
      return { success: true, message: 'Last appointment successfully deleted' };
    } catch (error) {
      return {
        success: false,
        message: error.message || 'An error occurred while deleting the appointment',
      };
    }
  }
}
