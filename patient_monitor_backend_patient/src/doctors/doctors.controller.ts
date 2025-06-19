import {
  Controller,
  Get,
  Patch,
  Param,
  Query,
  Body,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { DoctorsService } from './doctors.service';
import { AppointmentStatus } from 'src/shared/schema/appointments.schema';

@Controller('doctors')
export class DoctorsController {
  constructor(private readonly doctorsService: DoctorsService) {}

  // @UseGuards(AuthGuard('jwt'))
  @Get(':doctorName/appointments')
  async getDoctorAppointments(
    @Param('doctorName') doctor: string, // Changed doctorId to doctorName
    @Query('status') status?: AppointmentStatus,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    try {
      // Parse dates if provided
      let startDateObj: Date | undefined;
      let endDateObj: Date | undefined;
      
      if (startDate) {
        startDateObj = new Date(startDate);
      }
      
      if (endDate) {
        endDateObj = new Date(endDate);
      }
      
      const appointments = await this.doctorsService.getDoctorAppointments(
        doctor, // Passing doctorName instead of doctorId
        status,
        startDateObj,
        endDateObj
      );
      
      return {
        success: true,
        count: appointments.length,
        appointments
      };
    } catch (error) {
      throw new HttpException(
        `Failed to fetch doctor appointments: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // @UseGuards(AuthGuard('jwt'))
  @Get(':doctorName/appointments/stats') // Changed doctorId to doctorName
  async getDoctorAppointmentStats(
    @Param('doctorName') doctor: string, // Changed doctorId to doctorName
  ) {
    try {
      const stats = await this.doctorsService.getDoctorAppointmentStats(doctor); // Passing doctorName instead of doctorId
      
      return {
        success: true,
        data: stats
      };
    } catch (error) {
      throw new HttpException(
        `Failed to fetch doctor appointment stats: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // @UseGuards(AuthGuard('jwt'))
  @Patch(':doctorName/appointments/:appointmentId/status') // Changed doctorId to doctorName
  async updateAppointmentStatus(
    @Param('doctorName') doctor: string, // Changed doctorId to doctorName
    @Param('appointmentId') appointmentId: string,
    @Body() body: { status: AppointmentStatus },
  ) {
    try {
      const appointment = await this.doctorsService.updateAppointmentStatus(
        appointmentId,
        doctor, // Passing doctorName instead of doctorId
        body.status
      );
      
      return {
        success: true,
        appointment
      };
    } catch (error) {
      throw new HttpException(
        `Failed to update appointment status: ${error.message}`,
        error instanceof HttpException ? error.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
}
