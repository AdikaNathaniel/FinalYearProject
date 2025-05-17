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
      // Build query based on provided filters
      const query: any = { doctor };

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

      // Get appointments matching query
      const appointments = await this.appointmentModel
        .find(query)
        .sort({ date: 1 })
        .exec();

      return appointments;
    } catch (error) {
      this.logger.error(`Error fetching doctor appointments: ${error.message}`);
      throw error;
    }
  }

  async getDoctorAppointmentStats(doctor: string): Promise<any> {
    try {
      const today = new Date();
      const startOfDay = new Date(today.setHours(0, 0, 0, 0));
      const endOfDay = new Date(today.setHours(23, 59, 59, 999));

      // Get today's appointments
      const todayAppointments = await this.appointmentModel.find({
        doctor,
        date: { $gte: startOfDay, $lte: endOfDay },
      }).exec();

      // Get pending appointments (those waiting for patient response)
      const pendingAppointments = await this.appointmentModel.find({
        doctor,
        status: 'pending',
      }).exec();

      // Get appointment counts by status
      const confirmedCount = await this.appointmentModel.countDocuments({
        doctor,
        status: 'confirmed',
      });

      const canceledCount = await this.appointmentModel.countDocuments({
        doctor,
        status: 'canceled',
      });

      const pendingCount = await this.appointmentModel.countDocuments({
        doctor,
        status: 'pending',
      });

      // Get upcoming appointments (next 7 days)
      const nextWeek = new Date();
      nextWeek.setDate(nextWeek.getDate() + 7);

      const upcomingAppointments = await this.appointmentModel.find({
        doctor,
        date: { $gte: today, $lte: nextWeek },
        status: 'confirmed', // Only include confirmed appointments for upcoming
      }).sort({ date: 1 }).exec();

      // Add summary of SMS response status
      const smsResponseSummary = {
        totalAppointments: confirmedCount + canceledCount + pendingCount,
        confirmedByPatient: confirmedCount,
        canceledByPatient: canceledCount,
        awaitingResponse: pendingCount,
        confirmationRate: confirmedCount / (confirmedCount + canceledCount + pendingCount) || 0,
      };

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
          total: confirmedCount + canceledCount + pendingCount,
          confirmationRate: Math.round(smsResponseSummary.confirmationRate * 100) + '%',
        },
        upcoming: {
          count: upcomingAppointments.length,
          appointments: upcomingAppointments,
        },
        smsResponseSummary,
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
    const appointment = await this.appointmentModel.findOne({
      _id: appointmentId,
      doctor,
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
    const appointment = await this.appointmentModel.findOne({
      _id: appointmentId,
      doctor,
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