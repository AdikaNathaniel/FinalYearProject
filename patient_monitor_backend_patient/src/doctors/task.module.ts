import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { 
  Appointment, 
  AppointmentSchema 
} from 'src/shared/schema/appointments.schema';
import { AppointmentsCronService } from './appointment.cron';
import { SharedModule } from './shared.module';

@Module({
  imports: [
    // Import Mongoose models
    MongooseModule.forFeature([
      { name: Appointment.name, schema: AppointmentSchema },
    ]),
    
    // Import the SharedModule which provides MessageService
    SharedModule,
  ],
  providers: [AppointmentsCronService],
  exports: [],
})
export class TasksModule {}