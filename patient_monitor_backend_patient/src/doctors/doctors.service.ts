import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  Appointment,
  AppointmentDocument,
  AppointmentStatus,
} from 'src/shared/schema/appointments.schema';
import { MessageService } from './sms-message.service';

@Injectable()
export class DoctorsService {
  private readonly logger = new Logger(DoctorsService.name);

  constructor(
    @InjectModel(Appointment.name)
    private readonly appointmentModel: Model<AppointmentDocument>,
    private readonly smsService: MessageService,
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
    
    // Format appointments for SMS
    const smsMessage = this.formatAppointmentsForSms(doctor, appointments, startDate, endDate, status);
    
    // Send SMS notification with formatted appointment details
    await this.smsService.sendSms(smsMessage);
    
    return appointments;
  } catch (error) {
    this.logger.error(`Error fetching doctor appointments: ${error.message}`);
    throw error;
  }
}

/**
 * Format appointments into well-constructed English for SMS
 */
private formatAppointmentsForSms(
  doctor: string, 
  appointments: AppointmentDocument[], 
  startDate?: Date, 
  endDate?: Date,
  status?: AppointmentStatus
): string {
  // Create header with doctor name and date range
  let dateRange = '';
  if (startDate && endDate) {
    dateRange = ` from ${this.formatDate(startDate)} to ${this.formatDate(endDate)}`;
  } else if (startDate) {
    dateRange = ` from ${this.formatDate(startDate)} onwards`;
  } else if (endDate) {
    dateRange = ` until ${this.formatDate(endDate)}`;
  }
  
  let statusText = status ? ` with status "${status}"` : '';
  
  let header = `Appointments for ${doctor}${dateRange}${statusText}:`;
  
  // Handle case with no appointments
  if (!appointments || appointments.length === 0) {
    return `${header}\nNo appointments found.`;
  }
  
  // Build details for each appointment
  let details = appointments.map((apt, index) => {
    const dateTime = this.formatDateTime(new Date(apt.date));
    const location = apt.location ? ` at ${apt.location}` : '';
    const purpose = apt.purpose ? ` for ${apt.purpose}` : '';
    
    return `${index + 1}. ${dateTime}: ${apt.patientName} (${apt.phone})${purpose}${location} - ${this.capitalizeFirst(apt.status)}`;
  }).join('\n');
  
  // Create summary
  const summary = `Total: ${appointments.length} appointment${appointments.length !== 1 ? 's' : ''}`;
  
  // Combine all parts
  return `${header}\n\n${details}\n\n${summary}`;
}

/**
 * Format date to readable string
 */
private formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

/**
 * Format date and time to readable string
 */
private formatDateTime(date: Date): string {
  const dateStr = this.formatDate(date);
  const timeStr = date.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  });
  
  return `${dateStr} ${timeStr}`;
}

/**
 * Capitalize first letter of a string
 */
private capitalizeFirst(text: string): string {
  if (!text) return '';
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
}



async getDoctorAppointmentStats(doctor: string): Promise<any> {
  try {
    this.logger.debug(`Fetching appointment stats for doctor: ${doctor}`);

    const doctorQuery = { doctor: { $regex: new RegExp(doctor, 'i') } };
    const today = new Date();
    const startOfDay = new Date(today.setHours(0, 0, 0, 0));
    const endOfDay = new Date(today.setHours(23, 59, 59, 999));
    const nextWeek = new Date();
    nextWeek.setDate(nextWeek.getDate() + 7);

    const [
      todayAppointments,
      pendingAppointments,
      confirmedAppointments,
      canceledAppointments,
      upcomingAppointments
    ] = await Promise.all([
      this.appointmentModel.find({ ...doctorQuery, date: { $gte: startOfDay, $lte: endOfDay } }).exec(),
      this.appointmentModel.find({ ...doctorQuery, status: 'pending' }).exec(),
      this.appointmentModel.find({ ...doctorQuery, status: 'confirmed' }).exec(),
      this.appointmentModel.find({ ...doctorQuery, status: 'canceled' }).exec(),
      this.appointmentModel.find({
        ...doctorQuery,
        date: { $gte: new Date(), $lte: nextWeek },
        status: 'confirmed',
      }).sort({ date: 1 }).exec(),
    ]);

    const stats = {
      confirmed: confirmedAppointments.length,
      canceled: canceledAppointments.length,
      pending: pendingAppointments.length,
      total: confirmedAppointments.length + canceledAppointments.length + pendingAppointments.length,
      confirmationRate:
        confirmedAppointments.length + canceledAppointments.length + pendingAppointments.length > 0
          ? Math.round((confirmedAppointments.length / (confirmedAppointments.length + canceledAppointments.length + pendingAppointments.length)) * 100) + '%'
          : '0%',
    };

    // ✅ Short summary message to actually send via SMS
    const shortSms = `📋 Dr. ${doctor}:\nPending: ${stats.pending}, Confirmed: ${stats.confirmed}, Canceled: ${stats.canceled}, Upcoming: ${upcomingAppointments.length}, Today: ${todayAppointments.length}.\nLogin to Awo)Pa for full details.`;

    // ✅ Long detailed SMS version to include in the JSON response
    const formatAppointments = (title: string, list: any[]) => {
      if (!list.length) return `${title}: None.`;
      const items = list.map((a, i) =>
        `${i + 1}. ${a.patientName} @ ${a.location} on ${new Date(a.date).toLocaleString()} - ${a.purpose}`
      );
      return `${title} (${list.length}):\n${items.join('\n')}`;
    };

    const detailedSms = `📋 Dr. ${doctor} Appointments:\n\n` +
      `${formatAppointments('Today', todayAppointments)}\n` +
      `${formatAppointments('Pending', pendingAppointments)}\n` +
      `${formatAppointments('Confirmed', confirmedAppointments)}\n` +
      `${formatAppointments('Canceled', canceledAppointments)}\n` +
      `${formatAppointments('Upcoming', upcomingAppointments)}\n\n` +
      `Summary:\nTotal: ${stats.total}, Confirmed: ${stats.confirmed}, Pending: ${stats.pending}, Canceled: ${stats.canceled}, Rate: ${stats.confirmationRate}`;

    // ✅ Send only the short version as SMS
    await this.smsService.sendSms(shortSms);

    // ✅ Return full result with long detailed SMS in response body
    return {
      today: {
        count: todayAppointments.length,
        appointments: todayAppointments,
      },
      pending: {
        count: pendingAppointments.length,
        appointments: pendingAppointments,
      },
      confirmed: {
        count: confirmedAppointments.length,
        appointments: confirmedAppointments,
      },
      canceled: {
        count: canceledAppointments.length,
        appointments: canceledAppointments,
      },
      upcoming: {
        count: upcomingAppointments.length,
        appointments: upcomingAppointments,
      },
      stats,
      smsSent: detailedSms, // only shown in response, not sent
    };
  } catch (error) {
    this.logger.error(`Error fetching appointment stats for ${doctor}: ${error.message}`);
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

    // Store old status for comparison
    const oldStatus = appointment.status;
    
    // Update appointment status
    appointment.status = status;
    if (status === 'confirmed' || status === 'canceled') {
      appointment.confirmedAt = new Date();
    }

    // Save the appointment
    await appointment.save();
    
    // Only send status change notification if status actually changed
    if (oldStatus !== status) {
      const statusMessage = this.smsService.formatStatusChangeSms(appointment);
      await this.smsService.sendSms(statusMessage);
    }
    
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

    // Store old status for comparison
    const oldStatus = appointment.status;
    
    // Update appointment status based on confirmation
    appointment.status = confirmation ? 'confirmed' : 'canceled';
    appointment.confirmed = confirmation;
    appointment.confirmedAt = new Date();

    // Save the appointment
    await appointment.save();
    
    // Send status change notification if status changed
    if (oldStatus !== appointment.status) {
      const statusMessage = this.smsService.formatStatusChangeSms(appointment);
      await this.smsService.sendSms(statusMessage);
    }
    
    return appointment;
  }
}