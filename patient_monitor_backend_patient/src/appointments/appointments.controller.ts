import { Body, Controller, Delete, Get, Post } from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import { CreateAppointmentDto } from 'src/users/dto/create-appointment.dto'; 
import { Appointment } from 'src/shared/schema/appointment.schema'; 

@Controller('appointments')
export class AppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  @Post()
  async create(@Body() createAppointmentDto: CreateAppointmentDto): Promise<Appointment> {
    return await this.appointmentsService.create(createAppointmentDto);
  }

  @Get()
  async findAll(): Promise<Appointment[]> {
    return await this.appointmentsService.findAll();
  }

  // Endpoint to remove the last appointment
  @Delete('last')
  public async removeLastAppointment(): Promise<{ success: boolean; message: string }> {
    try {
      const result = await this.appointmentsService.removeLastAppointment();
      return { success: true, message: result.message }; // Adjust according to your service response
    } catch (error) {
      return { success: false, message: error.message };
    }
  }
}