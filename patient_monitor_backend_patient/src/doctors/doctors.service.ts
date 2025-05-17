
import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  Appointment,
  AppointmentDocument,
  AppointmentStatus,
} from 'src/shared/schema/appointments.schema';

@Injectable()
export class DoctorsService {
  private readonly logger = new Logger(DoctorsService.name);

  constructor(
    @InjectModel(Appointment.name)
    private readonly appointmentModel: Model<AppointmentDocument>,
  ) {}

  async getDoctorAppointments(
    doctor: string,
    status?: AppointmentStatus,
    startDate?: Date,
    endDate?: Date
  ): Promise<AppointmentDocument[]> {
    try {
      // Log the parameters for debugging
      this.logger.debug(`Fetching appointments for doctor: ${doctor}, status: ${status}, startDate: ${startDate}, endDate: ${endDate}`);
      
      // Build query based on provided filters
      const query: any = {};
      
      // Use regex for case-insensitive doctor search
      query.doctor = { $regex: new RegExp(doctor, 'i') };

      if (status) {
        query.status = status;
      }

      if (startDate || endDate) {
        query.date = {};
        if (startDate) {
          query.date.$gte = startDate;
        }
        if (endDate) {
          query.date.$lte = endDate;
        }
      }

      // Log the final query for debugging
      this.logger.debug(`Query for appointments: ${JSON.stringify(query)}`);

      // Get appointments matching query
      const appointments = await this.appointmentModel
        .find(query)
        .sort({ date: 1 })
        .exec();
      
      this.logger.debug(`Found ${appointments.length} appointments`);
      return appointments;
    } catch (error) {
      this.logger.error(`Error fetching doctor appointments: ${error.message}`);
      throw error;
    }
  }

  async getDoctorAppointmentStats(doctor: string): Promise<any> {
    try {
      this.logger.debug(`Getting appointment stats for doctor: ${doctor}`);
      
      // First, let's check if we can find any appointments at all for this doctor
      const allAppointments = await this.appointmentModel.find().exec();
      this.logger.debug(`Total appointments in database: ${allAppointments.length}`);
      
      // List all unique doctors in the system for debugging
      const uniqueDoctors = [...new Set(allAppointments.map(a => a.doctor))];
      this.logger.debug(`All doctors in system: ${JSON.stringify(uniqueDoctors)}`);
      
      // Use a more flexible query for doctor name (case insensitive)
      const doctorQuery = { doctor: { $regex: new RegExp(doctor, 'i') } };
      
      const doctorAppointments = await this.appointmentModel.find(doctorQuery).exec();
      this.logger.debug(`Found ${doctorAppointments.length} appointments for doctor: ${doctor}`);

      const today = new Date();
      const startOfDay = new Date(today);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(today);
      endOfDay.setHours(23, 59, 59, 999);

      // Get today's appointments
      const todayAppointments = await this.appointmentModel.find({
        ...doctorQuery,
        date: { $gte: startOfDay, $lte: endOfDay },
      }).exec();
      this.logger.debug(`Today's appointments: ${todayAppointments.length}`);

      // Get pending appointments (those waiting for patient response)
      const pendingAppointments = await this.appointmentModel.find({
        ...doctorQuery,
        status: 'pending',
      }).exec();
      this.logger.debug(`Pending appointments: ${pendingAppointments.length}`);

      // Get appointment counts by status
      const confirmedCount = await this.appointmentModel.countDocuments({
        ...doctorQuery,
        status: 'confirmed',
      });
      this.logger.debug(`Confirmed count: ${confirmedCount}`);

      const canceledCount = await this.appointmentModel.countDocuments({
        ...doctorQuery,
        status: 'canceled',
      });
      this.logger.debug(`Canceled count: ${canceledCount}`);

      const pendingCount = pendingAppointments.length;

      // Get upcoming appointments (next 7 days)
      const nextWeek = new Date(today);
      nextWeek.setDate(nextWeek.getDate() + 7);

      const upcomingAppointments = await this.appointmentModel.find({
        ...doctorQuery,
        date: { $gte: today, $lte: nextWeek },
        status: 'confirmed', // Only include confirmed appointments for upcoming
      }).sort({ date: 1 }).exec();
      this.logger.debug(`Upcoming appointments: ${upcomingAppointments.length}`);

      // Add summary of SMS response status
      const totalAppointments = confirmedCount + canceledCount + pendingCount;
      const confirmationRate = totalAppointments > 0 
        ? (confirmedCount / totalAppointments) 
        : 0;

      return {
        today: {
          count: todayAppointments.length,
          appointments: todayAppointments,
        },
        pending: {
          count: pendingCount,
          appointments: pendingAppointments,
        },
        stats: {
          confirmed: confirmedCount,
          canceled: canceledCount,
          pending: pendingCount,
          total: totalAppointments,
          confirmationRate: Math.round(confirmationRate * 100) + '%',
        },
        upcoming: {
          count: upcomingAppointments.length,
          appointments: upcomingAppointments,
        },
      };
    } catch (error) {
      this.logger.error(`Error fetching doctor appointment stats: ${error.message}`);
      throw error;
    }
  }

  async updateAppointmentStatus(
    appointmentId: string,
    doctor: string,
    status: AppointmentStatus
  ): Promise<AppointmentDocument> {
    const doctorQuery = { doctor: { $regex: new RegExp(doctor, 'i') } };
    
    const appointment = await this.appointmentModel.findOne({
      _id: appointmentId,
      ...doctorQuery,
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    appointment.status = status;
    if (status === 'confirmed' || status === 'canceled') {
      appointment.confirmedAt = new Date();
    }

    await appointment.save();
    return appointment;
  }

  // New method to handle manual confirmation/cancellation from doctor's interface
  async handleAppointmentConfirmation(
    appointmentId: string,
    doctor: string,
    confirmation: boolean
  ): Promise<AppointmentDocument> {
    const doctorQuery = { doctor: { $regex: new RegExp(doctor, 'i') } };
    
    const appointment = await this.appointmentModel.findOne({
      _id: appointmentId,
      ...doctorQuery,
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    appointment.status = confirmation ? 'confirmed' : 'canceled';
    appointment.confirmed = confirmation;
    appointment.confirmedAt = new Date();


    await appointment.save();
    return appointment;
  }
}